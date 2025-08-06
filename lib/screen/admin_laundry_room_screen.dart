import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLaundryRoomScreen extends StatefulWidget {
  final String machineName;

  const AdminLaundryRoomScreen({super.key, required this.machineName});

  @override
  State<AdminLaundryRoomScreen> createState() => _AdminLaundryRoomScreenState();
}

class _AdminLaundryRoomScreenState extends State<AdminLaundryRoomScreen> {
  bool isAvailable = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    print("Admin melihat mesin: ${widget.machineName}");

    _fetchMachineStatus();
  }

  Future<void> _fetchMachineStatus() async {
    final doc = await FirebaseFirestore.instance
        .collection('washing_machines')
        .doc(widget.machineName)
        .get();

    final data = doc.data();
    if (data != null && data.containsKey('isAvailable')) {
      setState(() {
        isAvailable = data['isAvailable'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateAvailability() async {
    try {
      // Update the washing_machines collection
      await FirebaseFirestore.instance
          .collection('washing_machines')
          .doc(widget.machineName)
          .set({'isAvailable': isAvailable}, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAvailable
              ? "Machine marked as available"
              : "Machine marked as unavailable"),
          backgroundColor: isAvailable ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      print('Error updating machine availability: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update status. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteQueueItem(String docId) async {
    await FirebaseFirestore.instance
        .collection('laundry_transactions')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Admin - ${widget.machineName}"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text("Machine Availability: "),
                Switch(
                  value: isAvailable,
                  onChanged: (value) {
                    setState(() => isAvailable = value);
                  },
                ),
                ElevatedButton(
                  onPressed: _updateAvailability,
                  child: const Text("Update"),
                )
              ],
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Queue List",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Modified query - removed the userRoom filter to show all transactions
                stream: FirebaseFirestore.instance
                    .collection('laundry_transactions')
                    .where('machineName', isEqualTo: widget.machineName)
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(child: Text("No active queue."));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;

                      final userName = data['userName'] ?? 'Unknown';
                      final userRoom = data['userRoom'] ?? '';
                      final userId = data['userId'] ?? '';
                      final timestamp = data['timestamp'] as Timestamp?;
                      final duration = data['totalMinutes'] ?? 0;

                      final washType = data['washType'] ?? '-';
                      final waterLevel = data['waterLevel'] ?? '-';
                      final airTurbo = data['airTurbo'] ?? '-';
                      final option = data['option'] ?? '-';

                      String timeInfo = "N/A";
                      if (timestamp != null && duration > 0) {
                        final endTime =
                            timestamp.toDate().add(Duration(minutes: duration));
                        final remaining =
                            endTime.difference(DateTime.now()).inMinutes;
                        timeInfo = remaining > 0
                            ? "$remaining min remaining"
                            : "Expired";
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text("$userName ($userRoom)"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("User ID: $userId"),
                              Text("Duration: $duration min"),
                              Text("Status: $timeInfo"),
                              Text("Wash Type: $washType"),
                              Text("Water Level: $waterLevel"),
                              Text("Air Turbo: $airTurbo"),
                              Text("Option: $option"),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Delete Queue"),
                                  content: const Text(
                                      "Are you sure you want to delete this queue entry?"),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text("Cancel")),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text("Delete")),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _deleteQueueItem(docs[index].id);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
