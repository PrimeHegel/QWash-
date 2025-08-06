import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminReportScreen extends StatelessWidget {
  const AdminReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Reports'),
        backgroundColor: const Color(0xFF3F51B5),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty)
            return const Center(child: Text('No reports found.'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, idx) {
              final data = docs[idx].data()! as Map<String, dynamic>;
              final message = data['message'] ?? '';
              final sender = data['sender'] ?? 'Unknown';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(sender,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(message),
                  trailing: timestamp != null
                      ? Text(
                          '${timestamp.day}/${timestamp.month}/${timestamp.year}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
