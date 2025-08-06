import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qwash/screen/laundry_room_screen.dart';
import 'package:qwash/screen/profile_screen.dart';
import 'package:qwash/widgets/custom_navbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _userName;
  String? _userRoom;
  bool _isLoading = true;
  List<Map<String, dynamic>> _machines = [];
  List<Map<String, dynamic>> _yourMachines = [];
  String? _userId;
  bool _isAdmin = false;

  // Track machine status changes for notifications
  Map<String, String> _previousStatus = {};
  // Track machine usage status for notifications
  Map<String, bool> _machineUsageStatus = {};
  // Track machine ID that was just added to queue
  String? _justAddedMachineId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _fetchUserData();

    // Initialize status tracking for notifications
    for (var machine in _machines) {
      _previousStatus[machine['id']] = machine['status'] ?? 'Unknown';
      _machineUsageStatus[machine['id']] = !machine['isAvailable'];
    }

    // Set up periodic status check for notifications
    _setupPeriodicStatusCheck();
  }

  void _setupPeriodicStatusCheck() {
    // Check for status changes every minute
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        _fetchMachineData().then((_) {
          _checkForStatusChanges();
          _setupPeriodicStatusCheck(); // Set up the next check
        });
      }
    });
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        _userName = userData['name'];
        _userRoom = userData['room'];
        _isAdmin = userData['role'] == 'admin';
      });

      await _fetchMachineData();

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMachineData() async {
    if (_userRoom == null || _userId == null) return;

    // Store previous machine lists to compare changes
    List<Map<String, dynamic>> previousMachines = List.from(_machines);
    List<Map<String, dynamic>> previousYourMachines = List.from(_yourMachines);

    // Create all machines based on user's floor
    await _createAllMachines();

    // Fetch user's machine queues
    await _fetchUserQueues();

    // Remove machines already in queue from available machines list
    _filterAvailableMachines();

    // Update UI after data is loaded
    if (mounted) {
      setState(() {});
    }

    // Check for any status changes after each update
    _checkForStatusChanges();

    // Check if any new machines were added to user's queue since last fetch
    _checkForNewlyUsedMachines(previousYourMachines);

    // For debugging
    print(
        "Fetched machine data: ${_machines.length} machines, ${_yourMachines.length} queued");
  }

  void _checkForStatusChanges() {
    // Check all machines (available and user's machines)
    List<Map<String, dynamic>> allMachines = [..._machines, ..._yourMachines];

    for (var machine in allMachines) {
      String machineId = machine['id'];
      String machineName = machine['name'];
      String newStatus = machine['status'] ?? 'Unknown';
      bool isCurrentlyAvailable = machine['isAvailable'] ?? false;

      // Get previous status (if exists)
      String? oldStatus = _previousStatus[machineId];
      bool? wasInUse = _machineUsageStatus[machineId];

      // If we have previous status to compare with
      if (oldStatus != null) {
        // Check if machine status changed from not available to available
        if (oldStatus == 'Not available' && newStatus == 'Available') {
          _showSnackBar('Machine ${machineName} is now available!');
        }
        // Check if machine is finishing soon
        else if (oldStatus.contains('mins left') &&
            newStatus == 'Almost done') {
          _showSnackBar('Machine ${machineName} is almost done!');
        }
        // Check if machine was completed
        else if ((oldStatus == 'Almost done' ||
                oldStatus.contains('mins left')) &&
            newStatus == 'Available') {
          _showSnackBar(
              'Machine ${machineName} has finished and is now available!');
        }
      }

      // Check if machine usage status changed
      if (wasInUse != null && !wasInUse && !isCurrentlyAvailable) {
        // Machine was available, now it's being used
        _showSnackBar('Machine ${machineName} is now being used.');
      }

      // Update previous status for next comparison
      _previousStatus[machineId] = newStatus;
      _machineUsageStatus[machineId] = !isCurrentlyAvailable;
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  Future<void> _createAllMachines() async {
    _machines = [];

    // Create a list of all machines based on floor with default "Available" status
    List<Map<String, dynamic>> tempMachines = [];

    // If admin, show all machines on all floors
    if (_isAdmin) {
      tempMachines = [
        _createMachine('Washer G1', 'Available'),
        _createMachine('Washer F1', 'Available'),
        _createMachine('Washer S1', 'Available'),
        _createMachine('Washer S2', 'Available'),
        _createMachine('Washer S3', 'Available'),
        _createMachine('Washer T1', 'Available'),
        _createMachine('Washer T2', 'Available'),
        _createMachine('Washer T3', 'Available'),
      ];
    } else {
      // Regular users only see machines based on their room
      switch (_userRoom) {
        case 'Ground Floor':
          tempMachines = [_createMachine('Washer G1', 'Available')];
          break;
        case 'First Floor':
          tempMachines = [_createMachine('Washer F1', 'Available')];
          break;
        case 'Second Floor':
          tempMachines = [
            _createMachine('Washer S1', 'Available'),
            _createMachine('Washer S2', 'Available'),
            _createMachine('Washer S3', 'Available'),
          ];
          break;
        case 'Third Floor':
          tempMachines = [
            _createMachine('Washer T1', 'Available'),
            _createMachine('Washer T2', 'Available'),
            _createMachine('Washer T3', 'Available'),
          ];
          break;
        default:
          tempMachines = [];
      }
    }

    // Check availability status for each machine from Firestore
    for (var machine in tempMachines) {
      String machineName = machine['name'];

      try {
        DocumentSnapshot machineDoc = await FirebaseFirestore.instance
            .collection('washing_machines')
            .doc(machineName)
            .get();

        if (machineDoc.exists) {
          Map<String, dynamic>? data =
              machineDoc.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('isAvailable')) {
            bool isAvailable = data['isAvailable'];
            machine['isAvailable'] = isAvailable;
            if (!isAvailable) {
              // Update machine status if not available
              machine['status'] = 'Not available';
              machine['color'] = Colors.red;
            }
          }
        }

        // Add machine to the final list regardless of availability
        // This ensures admin can still see all machines
        _machines.add(machine);
      } catch (e) {
        print('Error checking machine $machineName availability: $e');
        // Add machine with default available status on error
        _machines.add(machine);
      }
    }
  }

  Map<String, dynamic> _createMachine(String name, String status,
      [Color color = Colors.green, bool isAvailable = true]) {
    return {
      'id': name.replaceAll(' ', '_').toLowerCase(),
      'name': name,
      'status': status,
      'color': color,
      'isAvailable': isAvailable,
    };
  }

  Future<void> _fetchUserQueues() async {
    // Clear current user machines
    _yourMachines = [];

    try {
      // Query to get active transactions for current user
      QuerySnapshot transactionSnap;
      if (_isAdmin) {
        transactionSnap = await FirebaseFirestore.instance
            .collection('laundry_transactions')
            .get();
      } else {
        transactionSnap = await FirebaseFirestore.instance
            .collection('laundry_transactions')
            .where('userId', isEqualTo: _userId)
            .where('userRoom', isEqualTo: _userRoom)
            .get();
      }

      if (transactionSnap.docs.isNotEmpty) {
        for (var doc in transactionSnap.docs) {
          var transactionData = doc.data() as Map<String, dynamic>;
          String machineName = transactionData['machineName'];
          int totalMinutes = transactionData['totalMinutes'] ?? 0;

          // Check if transaction is still active (not expired)
          Timestamp? timestamp = transactionData['timestamp'] as Timestamp?;
          if (timestamp != null) {
            DateTime endTime =
                timestamp.toDate().add(Duration(minutes: totalMinutes));
            if (DateTime.now().isAfter(endTime)) {
              // Transaction has expired, no need to display
              continue;
            }
          }

          // Find machine in our list by name
          int machineIndex =
              _machines.indexWhere((m) => m['name'] == machineName);

          if (machineIndex != -1) {
            // Make a copy of the machine for user's list
            Map<String, dynamic> userMachine = {..._machines[machineIndex]};

            // Calculate time remaining
            String timeLeft = 'Processing...';
            if (timestamp != null && totalMinutes > 0) {
              DateTime endTime =
                  timestamp.toDate().add(Duration(minutes: totalMinutes));
              int minsLeft = endTime.difference(DateTime.now()).inMinutes;
              if (minsLeft > 0) {
                timeLeft = '$minsLeft mins left';
              } else {
                timeLeft = 'Almost done';
              }
            }

            userMachine['status'] = timeLeft;
            userMachine['color'] = Colors.blue;
            userMachine['transactionId'] =
                doc.id; // Save transaction document ID

            // Add to user's machines
            _yourMachines.add(userMachine);

            // IMPORTANT: Remove machine from available list
            _machines.removeAt(machineIndex);
          } else {
            // If machine not found in list (maybe already removed),
            // add new machine to user's list based on transaction data
            Map<String, dynamic> newUserMachine = {
              'id': machineName.replaceAll(' ', '_').toLowerCase(),
              'name': machineName,
              'status': 'Processing...',
              'color': Colors.blue,
              'isAvailable': false,
              'transactionId': doc.id,
            };

            if (timestamp != null && totalMinutes > 0) {
              DateTime endTime =
                  timestamp.toDate().add(Duration(minutes: totalMinutes));
              int minsLeft = endTime.difference(DateTime.now()).inMinutes;
              if (minsLeft > 0) {
                newUserMachine['status'] = '$minsLeft mins left';
              } else {
                newUserMachine['status'] = 'Almost done';
              }
            }

            _yourMachines.add(newUserMachine);
          }
        }
      }

      // If no transactions in Firestore, also check queue collection
      if (_yourMachines.isEmpty) {
        QuerySnapshot queueSnap;
        if (_isAdmin) {
          queueSnap = await FirebaseFirestore.instance
              .collection('queues')
              .where('isActive', isEqualTo: true)
              .get();
        } else {
          queueSnap = await FirebaseFirestore.instance
              .collection('queues')
              .where('userId', isEqualTo: _userId)
              .where('isActive', isEqualTo: true)
              .get();
        }

        for (var doc in queueSnap.docs) {
          var queueData = doc.data() as Map<String, dynamic>;
          String machineId = queueData['machineId'];

          // Find machine in our list
          int machineIndex = _machines.indexWhere((m) => m['id'] == machineId);

          if (machineIndex != -1) {
            // Make a copy of machine for user's queue
            Map<String, dynamic> userMachine = {..._machines[machineIndex]};

            // Calculate time remaining if available
            String timeLeft = '45 mins left'; // Default value
            if (queueData.containsKey('estimatedEndTime')) {
              DateTime endTime =
                  (queueData['estimatedEndTime'] as Timestamp).toDate();
              int minsLeft = endTime.difference(DateTime.now()).inMinutes;
              if (minsLeft > 0) {
                timeLeft = '$minsLeft mins left';
              } else {
                timeLeft = 'Almost done';
              }
            }

            userMachine['status'] = timeLeft;
            userMachine['color'] = Colors.blue;
            userMachine['queueId'] = doc.id; // Save queue document ID

            // Add to user's machines
            _yourMachines.add(userMachine);

            // IMPORTANT: Remove machine from available list
            _machines.removeAt(machineIndex);
          }
        }
      }
    } catch (e) {
      print('Error fetching user queues: $e');
    }

    // Debug info
    print('Your machines count: ${_yourMachines.length}');
    _yourMachines
        .forEach((m) => print('Your machine: ${m['name']} - ${m['status']}'));
  }

  // This method is no longer needed as we remove machines directly from _machines
  // when adding them to _yourMachines in _fetchUserQueues()
  void _filterAvailableMachines() {
    // This method is now empty as filtering is done directly
    // inside _fetchUserQueues()
  }

  // Called when user adds themselves to queue from LaundryRoomScreen
  // Add this new method to check for newly used machines
  void _checkForNewlyUsedMachines(
      List<Map<String, dynamic>> previousYourMachines) {
    // If we have new machines in yourMachines that weren't there before
    for (var machine in _yourMachines) {
      // Check if this machine wasn't in the previous list
      bool isNewlyAdded =
          !previousYourMachines.any((m) => m['id'] == machine['id']);

      if (isNewlyAdded) {
        // This is a newly added machine - show notification
        _showSnackBar('Machine ${machine['name']} is now being used.');
      }
    }
  }

  // ADDED METHOD: Implement the missing addToQueue method
  Future<void> addToQueue(String machineId, int minutes) async {
    if (_userId == null || _userRoom == null) return;

    try {
      // Find the machine by ID
      int machineIndex = _machines.indexWhere((m) => m['id'] == machineId);
      if (machineIndex == -1) {
        _showSnackBar('Machine not found or already in use');
        return;
      }

      // Get machine details
      String machineName = _machines[machineIndex]['name'];

      // 1. Update machine status in Firestore
      await FirebaseFirestore.instance
          .collection('washing_machines')
          .doc(machineName)
          .update({'isAvailable': false});

      // 2. Create a new transaction document
      DocumentReference transactionRef = await FirebaseFirestore.instance
          .collection('laundry_transactions')
          .add({
        'userId': _userId,
        'userRoom': _userRoom,
        'machineId': machineId,
        'machineName': machineName,
        'timestamp': FieldValue.serverTimestamp(),
        'totalMinutes': minutes,
        'isActive': true
      });

      // Set just added machine ID for notification
      _justAddedMachineId = machineId;

      // 3. Refresh data to update the UI
      await _fetchMachineData();

      _showSnackBar('Added to queue: $machineName');
    } catch (e) {
      print('Error adding to queue: $e');
      _showSnackBar('Failed to add to queue. Please try again.');
    }
  }

  Future<void> _refreshUserDataSilently() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          _userName = userData['name'];
          _userRoom = userData['room'];
        });

        await _fetchMachineData();

        // Show notification for newly added machine when returning to home screen
        if (_justAddedMachineId != null) {
          // Find the machine in your machines list
          var machine = _yourMachines.firstWhere(
              (m) => m['id'] == _justAddedMachineId,
              orElse: () => {
                    'name': _justAddedMachineId
                            ?.replaceAll('_', ' ')
                            .toUpperCase() ??
                        'Unknown'
                  });

          // Show notification that machine is in use
          _showSnackBar('Machine ${machine['name']} is now being used by you.');

          // Clear the just added machine ID
          _justAddedMachineId = null;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> screens = [
      HomeScreenWidget(
        userName: _userName,
        userRoom: _userRoom,
        machines: _machines,
        yourMachines: _yourMachines,
        refreshData: _fetchMachineData,
        onAddToQueue: addToQueue,
      ),
      const ProfileScreen(),
    ];
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
        child: IndexedStack(
          index: _selectedIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0) {
            _refreshUserDataSilently();
          }
        },
      ),
    );
  }
}

class HomeScreenWidget extends StatelessWidget {
  final String? userName;
  final String? userRoom;
  final List<Map<String, dynamic>> machines;
  final List<Map<String, dynamic>> yourMachines;
  final Future<void> Function() refreshData;
  final Future<void> Function(String, int) onAddToQueue;

  const HomeScreenWidget({
    super.key,
    this.userName,
    this.userRoom,
    required this.machines,
    required this.yourMachines,
    required this.refreshData,
    required this.onAddToQueue,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refreshData,
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
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          "Hello, ${userName ?? 'User'}!",
                          key: ValueKey(userName),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none,
                        color: Colors.black),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No new notifications')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Show available washing machines on user's floor
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  "Available Laundry on ${userRoom ?? '-'}",
                  key: ValueKey(userRoom),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              if (machines.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      "No machines available on this floor",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...machines
                    .map((machine) =>
                        _buildMachineCard(context, machine, refreshData, false))
                    .toList(),

              const SizedBox(height: 24),

              // Your laundry section
              const Text(
                "Your laundry",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (yourMachines.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      "You have no active laundry",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...yourMachines
                    .map((machine) =>
                        _buildMachineCard(context, machine, refreshData, true))
                    .toList(),

              // Extra space at bottom for better scroll experience
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMachineCard(BuildContext context, Map<String, dynamic> machine,
      Function refreshData, bool isUserMachine) {
    // Check if machine is available - prevent interaction if not available
    bool isNotAvailable = !isUserMachine && !machine['isAvailable'];

    return MouseRegion(
      cursor: isNotAvailable
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        // Only allow tap if machine is available or if it's the user's machine
        onTap: isNotAvailable
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LaundryRoomScreen(
                      machineName: machine['name'],
                      isAvailable: machine['isAvailable'],
                    ),
                  ),
                ).then((_) => refreshData());
              },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isNotAvailable ? Colors.grey.shade200 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            // Add a red border for unavailable machines
            border: isNotAvailable
                ? Border.all(color: Colors.red.shade300, width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                Icons.local_laundry_service,
                size: 32,
                color: isUserMachine
                    ? Colors.blue
                    : (machine['isAvailable'] ? Colors.indigo : Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  machine['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    // Grey out the text for unavailable machines
                    color: isNotAvailable ? Colors.grey : Colors.black,
                  ),
                ),
              ),
              Text(
                machine['status'],
                style: TextStyle(
                  color: machine['color'],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
