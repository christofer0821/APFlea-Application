import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import 'manage_listings.dart';
import 'verify_users.dart';
import 'admin_profile.dart'; // Placeholder

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    AdminDashboard(),
    ManageListingsPage(),
    VerifyUsersPage(),
    AdminProfilePage(),
  ];

  final List<String> _titles = [
    "Dashboard",
    "Listings",
    "Users",
    "Profile",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Listings"),
          BottomNavigationBarItem(icon: Icon(Icons.verified_user), label: "Users"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
