import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LaundryAddScreen extends StatefulWidget {
  final String machineName;

  const LaundryAddScreen({super.key, required this.machineName});

  @override
  State<LaundryAddScreen> createState() => _LaundryAddScreenState();
}

class _LaundryAddScreenState extends State<LaundryAddScreen> {
  final Color primaryColor = const Color(0xFF3F51B5);
  String? _userRoom;
  bool _isLoading = true;

  int selectedWashType = -1; // default tidak ada pilihan
  int? selectedWaterLevel;
  int? selectedAirTurbo;
  int? selectedOption;

  final List<String> washTypes = [
    'Normal Wash',
    'Fuzzy',
    'Delicates',
    'Blanket'
  ];
  final List<String> options = ['Wash', 'Rinse', 'Spin'];

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

        setState(() {
          _userRoom = userRoom;
          _isLoading = false;
        });
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

  int calculateTotalMinutes() {
    int total = 0;
    switch (selectedWashType) {
      case 0:
        total += 50;
        break;
      case 1:
        total += 60;
        break;
      case 2:
        total += 45;
        break;
      case 3:
        total += 70;
        break;
    }
    if (selectedAirTurbo != null) {
      total += selectedAirTurbo!;
    }
    return total;
  }

  Future<void> saveLaundryData() async {
    if (selectedWashType == -1 &&
        selectedWaterLevel == null &&
        selectedOption == null &&
        selectedAirTurbo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one option')),
      );
      return;
    }

    if (_userRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Your floor information is not available')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    try {
      final userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final userName = userSnapshot.data()?['name'] ?? 'Unknown';
      // Make sure we're using the _userRoom value we fetched in initState
      final userRoom = _userRoom;

      final data = {
        'machineName': widget.machineName,
        'washType': selectedWashType != -1 ? washTypes[selectedWashType] : null,
        'waterLevel': selectedWaterLevel,
        'airTurbo': selectedAirTurbo ?? 0,
        'option': selectedOption != null ? options[selectedOption!] : null,
        'totalMinutes': calculateTotalMinutes(),
        'timestamp': FieldValue.serverTimestamp(),
        'userId': uid,
        'userName': userName,
        'userRoom': userRoom, // Ensure userRoom is always included
      };

      final docRef = await FirebaseFirestore.instance
          .collection('laundry_transactions')
          .add(data);

      // Wait until serverTimestamp is actually available
      await FirebaseFirestore.instance
          .collection('laundry_transactions')
          .doc(docRef.id)
          .snapshots()
          .firstWhere((doc) => doc.data()?['timestamp'] != null);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laundry data saved successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMinutes = calculateTotalMinutes();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.machineName),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
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
        title: Text("${widget.machineName} (${_userRoom ?? 'Unknown Floor'})"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const Text(
              "Choose wash type",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Column(
              children: List.generate(washTypes.length, (index) {
                bool isSelected = selectedWashType == index;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.local_laundry_service,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                    title: Text(
                      washTypes[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        if (selectedWashType == index) {
                          selectedWashType = -1; // unselect
                        } else {
                          selectedWashType = index;
                        }
                      });
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            const Text("Choose water level",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                int level = index + 1;
                bool isSelected = selectedWaterLevel == level;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selectedWaterLevel == level) {
                        selectedWaterLevel = null; // unselect
                      } else {
                        selectedWaterLevel = level;
                      }
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$level',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            const Text("Choose air turbo",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [15, 30].map((minute) {
                bool isSelected = selectedAirTurbo == minute;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selectedAirTurbo == minute) {
                        selectedAirTurbo = null; // unselect
                      } else {
                        selectedAirTurbo = minute;
                      }
                    });
                  },
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$minute min',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text("Choose laundry option",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(options.length, (index) {
                bool isSelected = selectedOption == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selectedOption == index) {
                        selectedOption = null; // unselect
                      } else {
                        selectedOption = index;
                      }
                    });
                  },
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      options[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  saveLaundryData(); // Panggil simpan ke Firebase
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  totalMinutes > 0 ? "$totalMinutes Min" : "Select options",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
