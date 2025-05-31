import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/forgot_password_page.dart';
import '../../auth/auth_gate.dart';

class SellerProfilePage extends StatefulWidget {
  const SellerProfilePage({super.key});

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  String? displayName;

  final Color backgroundColor = const Color(0xFFF5F5F7);
  final Color textColor = const Color(0xFF333333);
  final Color highlightBlue = const Color(0xFF2d8cff);

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    setState(() {
      displayName = doc.data()?['name'] ?? user!.email;
    });
  }

  Future<void> _changeNameDialog() async {
    final controller = TextEditingController(text: displayName);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Change Name"),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'name': name});
                setState(() => displayName = name);
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _goToForgotPassword() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage()));
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to permanently delete your account? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).delete();
      await user!.delete();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const CircleAvatar(radius: 40, backgroundColor: Color(0xFFE0E0E0), child: Icon(Icons.person, size: 40, color: Color(0xFF555555))),
                const SizedBox(height: 12),
                Text(user?.email ?? "Unknown", style: TextStyle(fontSize: 16, color: textColor)),
                Text("Name: ${displayName ?? 'Loading...'}", style: TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildTile(Icons.edit, "Change Name", _changeNameDialog),
          _buildTile(Icons.lock, "Change Password", _goToForgotPassword),
          const Divider(height: 32),
          _buildTile(Icons.logout, "Log Out", _logout, iconColor: Colors.red, textColor: Colors.red),
          _buildTile(Icons.delete_forever, "Delete Account", _deleteAccount, iconColor: Colors.red, textColor: Colors.red),
        ],
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, VoidCallback onTap,
      {Color? iconColor, Color? textColor}) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? textColor ?? this.textColor),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? this.textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
