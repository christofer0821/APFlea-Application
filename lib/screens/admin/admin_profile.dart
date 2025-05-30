import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logged out")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 60),
            const CircleAvatar(radius: 40, child: Icon(Icons.admin_panel_settings, size: 40)),
            const SizedBox(height: 20),
            Text(user?.email ?? "Unknown admin", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
