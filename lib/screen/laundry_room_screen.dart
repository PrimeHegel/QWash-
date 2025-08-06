import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'laundry_add_screen.dart';

class LaundryRoomScreen extends StatefulWidget {
  final String machineName;
  final bool isAvailable;

  const LaundryRoomScreen(
      {super.key, required this.machineName, this.isAvailable = true});

  @override
  State<LaundryRoomScreen> createState() => _LaundryRoomScreenState();
}

class _LaundryRoomScreenState extends State<LaundryRoomScreen> {
  final Color primaryColor = const Color(0xFF3F51B5);
  String? _userRoom;
  bool _isLoading = true;
  bool _isUserInQueue = false; // Track if current user is already in queue

  @override
  void initState() {
    super.initState();
    _fetchUserRoom();
  }

  Future<void> _fetchUserRoom() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final userRoom = userDoc.data()?['room'];

        // Print untuk debugging
        print('Fetched userRoom: $userRoom');

        setState(() {
          _userRoom = userRoom;
          _isLoading = false;
        });

        // Check if user is already in queue
        _checkIfUserInQueue(uid);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user room: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkIfUserInQueue(String uid) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('laundry_transactions')
          .where('machineName', isEqualTo: widget.machineName)
          .where('userId', isEqualTo: uid)
          .get();

      final activeTransactions = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        final totalMinutes = data['totalMinutes'] ?? 0;

        if (timestamp == null || totalMinutes <= 0) return false;

        final endTime = timestamp.toDate().add(Duration(minutes: totalMinutes));
        final now = DateTime.now();
        return now.isBefore(endTime); // Only active transactions
      }).toList();

      setState(() {
        _isUserInQueue = activeTransactions.isNotEmpty;
      });
    } catch (e) {
      print('Error checking user queue status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.machineName),
          leading: const BackButton(color: Colors.black),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.machineName),
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.local_laundry_service, color: Colors.indigo),
                SizedBox(width: 8),
                Text("In use", style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  "Queue:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                // Display which floor's queue is being shown
                if (_userRoom != null)
                  Text(
                    "($_userRoom)",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('laundry_transactions')
                    .where('machineName', isEqualTo: widget.machineName)
                    // Only filter by userRoom if we have the value
                    .where('userRoom',
                        isEqualTo: _userRoom) // This is the key fix
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Text("No queue yet on this floor.");
                  }

                  final validDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] as Timestamp?;
                    final totalMinutes = data['totalMinutes'] ?? 0;

                    if (timestamp == null || totalMinutes <= 0) return false;

                    final endTime =
                        timestamp.toDate().add(Duration(minutes: totalMinutes));
                    final now = DateTime.now();
                    if (now.isAfter(endTime)) {
                      FirebaseFirestore.instance
                          .collection('laundry_transactions')
                          .doc(doc.id)
                          .delete();
                      return false;
                    }
                    return true;
                  }).toList();

                  // Sort manually by timestamp
                  validDocs.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aTimestamp = aData['timestamp'] as Timestamp;
                    final bTimestamp = bData['timestamp'] as Timestamp;
                    return aTimestamp.compareTo(bTimestamp);
                  });

                  // Check if current user is in queue and update _isUserInQueue
                  final currentUid = FirebaseAuth.instance.currentUser?.uid;
                  if (currentUid != null) {
                    final userInQueue = validDocs.any((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['userId'] == currentUid;
                    });

                    if (_isUserInQueue != userInQueue) {
                      // Only update state if needed to avoid rebuild loops
                      Future.microtask(() {
                        setState(() {
                          _isUserInQueue = userInQueue;
                        });
                      });
                    }
                  }

                  if (validDocs.isEmpty) {
                    return const Text("No active queue on this floor.");
                  }

                  return ListView.builder(
                    itemCount: validDocs.length,
                    itemBuilder: (context, index) {
                      final data =
                          validDocs[index].data() as Map<String, dynamic>;
                      final userName = data['userName'] ?? 'User';
                      final timestamp = data['timestamp'] as Timestamp?;
                      final totalMinutes = data['totalMinutes'] ?? 0;
                      final userId = data['userId'];
                      final isCurrentUser =
                          userId == FirebaseAuth.instance.currentUser?.uid;

                      if (index == 0 && timestamp != null && totalMinutes > 0) {
                        final now = DateTime.now();
                        final endTime = timestamp
                            .toDate()
                            .add(Duration(minutes: totalMinutes));
                        final remaining = endTime.difference(now);

                        return _buildQueueItemWithTimer(
                            userName, remaining, isCurrentUser);
                      } else {
                        return _buildQueueItem(userName, "Waiting",
                            isActive: isCurrentUser);
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isUserInQueue
                    ? null
                    : () async {
                        if (_userRoom == null) {
                          // Tampilkan pesan error jika userRoom kosong
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Data lantai/kamar Anda belum tersedia. Silakan coba lagi.')),
                          );
                          return;
                        }

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LaundryAddScreen(
                                machineName: widget.machineName),
                          ),
                        );
                        setState(() {}); // Trigger rebuild after returning
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  // Button will be disabled if user is already in queue
                  disabledBackgroundColor: Colors.grey,
                ),
                child: Text(
                  _isUserInQueue ? "Already in Queue" : "Add",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueItemWithTimer(
      String name, Duration remaining, bool isCurrentUser) {
    return TweenAnimationBuilder<Duration>(
      duration: remaining,
      tween: Tween(begin: remaining, end: Duration.zero),
      onEnd: () {
        setState(() {}); // Refresh to remove expired
      },
      builder: (context, value, child) {
        final minutes = value.inMinutes;
        final seconds = value.inSeconds % 60;
        final countdown = '$minutes:${seconds.toString().padLeft(2, '0')}';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF3F51B5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.local_laundry_service,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCurrentUser ? "$name (You)" : name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                countdown,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildQueueItem(String name, String status,
      {bool isActive = false, bool isCurrentUser = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF3F51B5) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_laundry_service,
            color: isActive ? Colors.white : Colors.black,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isCurrentUser ? "$name (You)" : name,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            status,
            style: TextStyle(color: isActive ? Colors.white : Colors.grey),
          ),
        ],
      ),
    );
  }
}
