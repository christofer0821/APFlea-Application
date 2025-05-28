import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuyerHomePage extends StatelessWidget {
  const BuyerHomePage({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logged out")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buyer Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: const Center(child: Text("Welcome Buyer!")),
    );
  }
}
