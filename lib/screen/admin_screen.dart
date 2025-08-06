import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qwash/screen/admin_laundry_room_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final Color primaryColor = const Color(0xFF3F51B5);
  bool _isLoading = true;
  String? _adminName;
  Timer? _timer;

  final List<String> floors = [
    'Ground Floor',
    'First Floor',
    'Second Floor',
    'Third Floor'
  ];

  Map<String, List<Map<String, dynamic>>> machinesByFloor = {};

  @override
  void initState() {
    super.initState();
    _fetchAdminData();

    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchAdminData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAdminData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        setState(() {
          _adminName = userData['name'];
        });
      }

      for (String floor in floors) {
        machinesByFloor[floor] = [];
      }

      await _fetchAllMachines();

      setState(() {
        _isLoading = false;
      });

      _showMachinesInUseSnackbar(); // ✅ Show Snackbar after fetching data
    } catch (e) {
      print('Error fetching admin data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAllMachines() async {
    try {
      for (String floor in floors) {
        machinesByFloor[floor] = [];
      }

      _createDefaultMachines();

      QuerySnapshot machinesSnap =
          await FirebaseFirestore.instance.collection('washing_machines').get();

      for (var doc in machinesSnap.docs) {
        String machineName = doc.id;
        bool isAvailable = doc.data() is Map<String, dynamic>
            ? (doc.data() as Map<String, dynamic>)['isAvailable'] ?? true
            : true;

        for (String floor in floors) {
          for (int i = 0; i < machinesByFloor[floor]!.length; i++) {
            if (machinesByFloor[floor]![i]['firestoreName'] == machineName) {
              machinesByFloor[floor]![i]['isAvailable'] = isAvailable;
              if (!isAvailable) {
                machinesByFloor[floor]![i]['status'] = 'Not Available';
                machinesByFloor[floor]![i]['isInUse'] = true;
              }
              break;
            }
          }
        }
      }

      QuerySnapshot transactionsSnap = await FirebaseFirestore.instance
          .collection('laundry_transactions')
          .get();

      for (var doc in transactionsSnap.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String machineName = data['machineName'] ?? '';
        String userRoom = data['userRoom'] ?? '';
        int totalMinutes = data['totalMinutes'] ?? 0;
        Timestamp? timestamp = data['timestamp'] as Timestamp?;

        if (machineName.isEmpty || userRoom.isEmpty || timestamp == null)
          continue;

        DateTime endTime =
            timestamp.toDate().add(Duration(minutes: totalMinutes));
        if (DateTime.now().isAfter(endTime)) continue;

        int minsLeft = endTime.difference(DateTime.now()).inMinutes;
        String timeLeft = '$minsLeft mins left';
        String formattedRoom = _capitalizeEachWord(userRoom.trim());

        for (String floor in floors) {
          for (int i = 0; i < machinesByFloor[floor]!.length; i++) {
            if (machinesByFloor[floor]![i]['firestoreName'] == machineName) {
              if (machinesByFloor[floor]![i]['isAvailable'] != false) {
                machinesByFloor[floor]![i]['status'] = timeLeft;
                machinesByFloor[floor]![i]['isInUse'] = true;
              }
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching machines: $e');
    }
  }

  void _createDefaultMachines() {
    machinesByFloor['Ground Floor'] = [
      _createMachine('Washing machine 1', 'Available',
          firestoreName: 'Washer G1'),
    ];

    machinesByFloor['First Floor'] = [
      _createMachine('Washing machine 1', 'Available',
          firestoreName: 'Washer F1'),
    ];

    machinesByFloor['Second Floor'] = [
      _createMachine('Washing machine 1', 'Available',
          firestoreName: 'Washer S1'),
      _createMachine('Washing machine 2', 'Available',
          firestoreName: 'Washer S2'),
      _createMachine('Washing machine 3', 'Available',
          firestoreName: 'Washer S3'),
    ];

    machinesByFloor['Third Floor'] = [
      _createMachine('Washing machine 1', 'Available',
          firestoreName: 'Washer T1'),
      _createMachine('Washing machine 2', 'Available',
          firestoreName: 'Washer T2'),
      _createMachine('Washing machine 3', 'Available',
          firestoreName: 'Washer T3'),
    ];
  }

  Map<String, dynamic> _createMachine(String name, String status,
      {required String firestoreName, bool isInUse = false}) {
    return {
      'name': name,
      'firestoreName': firestoreName,
      'status': status,
      'isInUse': isInUse,
      'isAvailable': true,
    };
  }

  String _capitalizeEachWord(String text) {
    return text
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchAdminData();
  }

  void _showMachinesInUseSnackbar() {
    List<String> inUseMachines = [];

    for (String floor in floors) {
      for (var machine in machinesByFloor[floor]!) {
        if (machine['isInUse'] == true) {
          inUseMachines.add('${machine['name']} ($floor)');
        }
      }
    }

    if (inUseMachines.isNotEmpty) {
      final snackBar = SnackBar(
        content: Text(
          'Machines in use: ${inUseMachines.join(', ')}',
          style: const TextStyle(fontSize: 14),
        ),
        duration: const Duration(seconds: 5),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Hello, ${_adminName ?? 'Hegel'}!",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none),
                        onPressed: () {
                          _showMachinesInUseSnackbar();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  for (String floor in floors) ...[
                    Text(
                      "Available Laundry in $floor",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    if (machinesByFloor[floor]!.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            "No machines on this floor",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: machinesByFloor[floor]!
                            .map((machine) =>
                                _buildMachineCard(context, machine, floor))
                            .toList(),
                      ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMachineCard(
      BuildContext context, Map<String, dynamic> machine, String floor) {
    Color statusColor;
    if (machine['isAvailable'] == false) {
      statusColor = Colors.red;
    } else if (machine['isInUse']) {
      statusColor = Colors.indigo;
    } else {
      statusColor = Colors.green;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminLaundryRoomScreen(
              machineName: machine['firestoreName'],
            ),
          ),
        ).then((_) => _refreshData());
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_laundry_service,
              size: 28,
              color: Colors.indigo.shade200,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                machine['name'],
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Text(
              machine['status'],
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
