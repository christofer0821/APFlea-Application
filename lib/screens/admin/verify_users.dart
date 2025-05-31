import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VerifyUsersPage extends StatefulWidget {
  const VerifyUsersPage({super.key});

  @override
  State<VerifyUsersPage> createState() => _VerifyUsersPageState();
}

class _VerifyUsersPageState extends State<VerifyUsersPage> {
  String _searchQuery = '';

  Future<void> _verifyUser(String docId) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).update({
      'verified': true,
      'verifiedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _deleteUser(String docId, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Block/Delete User"),
        content: const Text("Are you sure you want to permanently delete this user?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User deleted")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFFF5F5F7);
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Search by email or role",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No users found."));
                }

                final filtered = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final email = data['email']?.toLowerCase() ?? '';
                  final role = data['role']?.toLowerCase() ?? '';
                  return email.contains(_searchQuery) || role.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 28)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['name'] ?? 'No Name',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(data['email'] ?? ''),
                                  Text("Role: ${data['role']}", style: const TextStyle(color: Colors.grey)),
                                  Text("Status: ${data['verified'] == true ? '✅ Verified' : '❌ Not Verified'}",
                                      style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                if (data['verified'] != true)
                                  IconButton(
                                    icon: const Icon(Icons.verified_user, color: Colors.green),
                                    tooltip: "Verify",
                                    onPressed: () => _verifyUser(doc.id),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.block, color: Colors.red),
                                  tooltip: "Delete",
                                  onPressed: () => _deleteUser(doc.id, context),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
