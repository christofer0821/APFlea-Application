import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SellerProfilePage extends StatelessWidget {
  const SellerProfilePage({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logged out")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 20),
            Text(user?.email ?? "No email", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            )
          ],
        ),
      ),
    );
  }
}
