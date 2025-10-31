import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageRescuersScreen extends StatelessWidget {
  const ManageRescuersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'rescuer')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Rescuers'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No rescuers found', style: TextStyle(fontSize: 16)),
            );
          }

          // Sort locally by creation date
          final rescuers = snapshot.data!.docs;
          rescuers.sort((a, b) {
            final aTime =
                (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
            final bTime =
                (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: rescuers.length,
            itemBuilder: (context, index) {
              final rescuer = rescuers[index].data() as Map<String, dynamic>;
              final docId = rescuers[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1565C0),
                    child: Text(
                      rescuer['name'] != null && rescuer['name'].isNotEmpty
                          ? rescuer['name'][0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    rescuer['name'] ?? 'Unknown Rescuer',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rescuer['email'] ?? ''),
                      if (rescuer['createdAt'] != null)
                        Text(
                          'Joined: ${(rescuer['createdAt'] as Timestamp).toDate().toLocal().toString().split(' ')[0]}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) async {
                      final ref = FirebaseFirestore.instance
                          .collection('users')
                          .doc(docId);

                      if (value == 'delete') {
                        await ref.delete();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Rescuer removed successfully'),
                            ),
                          );
                        }
                      } else if (value == 'promote') {
                        await ref.update({'role': 'admin'});

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Rescuer promoted to Admin'),
                            ),
                          );
                        }
                      }
                    },

                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'promote',
                        child: Row(
                          children: [
                            Icon(Icons.upgrade, color: Colors.black54),
                            SizedBox(width: 8),
                            Text('Promote to Admin'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Remove Rescuer'),
                          ],
                        ),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
