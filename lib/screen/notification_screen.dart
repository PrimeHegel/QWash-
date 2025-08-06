import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  String? _userId;
  bool _isAdmin = false;
  String? _userRoom;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
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
        _isAdmin = userData['role'] == 'admin';
        _userRoom = userData['room'];
      });

      await _fetchNotifications();

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      // Clear existing notifications
      _notifications = [];

      // Get active laundry transactions
      QuerySnapshot transactionSnap;

      if (_isAdmin) {
        // Admin sees all transactions
        transactionSnap = await FirebaseFirestore.instance
            .collection('laundry_transactions')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .get();
      } else {
        // Regular users only see their own transactions
        transactionSnap = await FirebaseFirestore.instance
            .collection('laundry_transactions')
            .where('userId', isEqualTo: _userId)
            .where('userRoom', isEqualTo: _userRoom)
            .orderBy('timestamp', descending: true)
            .limit(20)
            .get();
      }

      // Process active laundry transactions
      for (var doc in transactionSnap.docs) {
        Map<String, dynamic> transactionData =
            doc.data() as Map<String, dynamic>;

        String machineName =
            transactionData['machineName'] ?? 'Unknown Machine';
        int totalMinutes = transactionData['totalMinutes'] ?? 45;
        Timestamp? timestamp = transactionData['timestamp'] as Timestamp?;

        if (timestamp != null) {
          DateTime startTime = timestamp.toDate();
          DateTime endTime = startTime.add(Duration(minutes: totalMinutes));
          bool isCompleted = DateTime.now().isAfter(endTime);

          // Create notification objects
          Map<String, dynamic> notification = {
            'id': doc.id,
            'title': isCompleted ? 'Laundry Completed!' : 'Laundry In Progress',
            'message': isCompleted
                ? '$machineName has finished your laundry!'
                : '$machineName is currently in use',
            'timestamp': timestamp,
            'isRead': false,
            'type': isCompleted ? 'completed' : 'inProgress',
            'machineName': machineName,
            'endTime': endTime,
          };

          // Add machine floor information for admins
          if (_isAdmin && transactionData.containsKey('userRoom')) {
            notification['userRoom'] = transactionData['userRoom'];
            notification['userName'] = transactionData['userName'] ?? 'User';
          }

          _notifications.add(notification);
        }
      }

      // Check for maintenance notifications (only for admin)
      if (_isAdmin) {
        QuerySnapshot maintenanceSnap = await FirebaseFirestore.instance
            .collection('maintenance')
            .orderBy('reportedAt', descending: true)
            .limit(10)
            .get();

        for (var doc in maintenanceSnap.docs) {
          Map<String, dynamic> maintenanceData =
              doc.data() as Map<String, dynamic>;

          Timestamp? reportedAt = maintenanceData['reportedAt'] as Timestamp?;
          String machineName =
              maintenanceData['machineName'] ?? 'Unknown Machine';
          String issue = maintenanceData['issue'] ?? 'Maintenance required';
          String reporter = maintenanceData['reporterName'] ?? 'A user';

          if (reportedAt != null) {
            Map<String, dynamic> notification = {
              'id': doc.id,
              'title': 'Maintenance Alert',
              'message': '$reporter reported: $issue on $machineName',
              'timestamp': reportedAt,
              'isRead': false,
              'type': 'maintenance',
              'machineName': machineName,
            };

            _notifications.add(notification);
          }
        }
      }

      // Sort notifications by timestamp (newest first)
      _notifications.sort((a, b) =>
          (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load notifications')));
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    // In a real app, you might want to store read status in Firestore
    setState(() {
      for (var notification in _notifications) {
        if (notification['id'] == notificationId) {
          notification['isRead'] = true;
          break;
        }
      }
    });
  }

  Future<void> _clearAllNotifications() async {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });

    // Optional: You could implement a Firestore write to mark notifications as read
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')));
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
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.blue),
              onPressed: _clearAllNotifications,
              tooltip: 'Mark all as read',
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchNotifications,
            tooltip: 'Refresh notifications',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: _notifications.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationCard(_notifications[index]);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when your laundry starts or finishes',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchNotifications,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    // Format timestamp
    Timestamp timestamp = notification['timestamp'] as Timestamp;
    DateTime dateTime = timestamp.toDate();
    String formattedTime = _formatDateTime(dateTime);

    // Get icon and color based on notification type
    IconData icon;
    Color iconColor;

    switch (notification['type']) {
      case 'completed':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'inProgress':
        icon = Icons.access_time;
        iconColor = Colors.blue;
        break;
      case 'maintenance':
        icon = Icons.build;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    // Get remaining time for in-progress notifications
    String timeInfo = '';
    if (notification['type'] == 'inProgress' &&
        notification.containsKey('endTime')) {
      DateTime endTime = notification['endTime'];
      if (DateTime.now().isBefore(endTime)) {
        int minsLeft = endTime.difference(DateTime.now()).inMinutes;
        timeInfo = '$minsLeft mins remaining';
      } else {
        timeInfo = 'Completed';
      }
    }

    return Dismissible(
      key: Key(notification['id']),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _markAsRead(notification['id']);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification dismissed')));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: notification['isRead'] ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: notification['isRead']
                ? Colors.grey.shade200
                : Colors.blue.shade100,
            width: notification['isRead'] ? 0.5 : 1.5,
          ),
        ),
        child: InkWell(
          onTap: () => _markAsRead(notification['id']),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: notification['isRead']
                              ? FontWeight.w500
                              : FontWeight.bold,
                          color: notification['isRead']
                              ? Colors.black87
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['message'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      // Show additional admin info if available
                      if (_isAdmin &&
                          notification.containsKey('userRoom') &&
                          notification.containsKey('userName'))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'User: ${notification['userName']} (${notification['userRoom']})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      // Show time information
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          if (timeInfo.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: timeInfo == 'Completed'
                                    ? Colors.green.shade100
                                    : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                timeInfo,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: timeInfo == 'Completed'
                                      ? Colors.green.shade800
                                      : Colors.blue.shade800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Read indicator
                if (!notification['isRead'])
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateToCheck == today) {
      return 'Today, ${DateFormat('h:mm a').format(dateTime)}';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(dateTime)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }
}
