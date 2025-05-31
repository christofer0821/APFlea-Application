import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import 'manage_listings.dart';
import 'verify_users.dart';
import 'admin_profile.dart';

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
    "Admin Dashboard",
    "Manage Listings",
    "Verify Users",
    "Profile",
  ];

  final Color backgroundColor = const Color(0xFFF5F5F7);
  final Color textColor = const Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: SafeArea(
            child: Image.asset(
              'assets/logo.png',
              height: 36,
              fit: BoxFit.contain,
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          _titles[_selectedIndex],
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF2d8cff),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
