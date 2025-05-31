import 'package:flutter/material.dart';
import 'buyer_home.dart';
import 'bookmark_screen.dart';
import 'buyer_profile.dart';
import 'buyer_requests_page.dart';
import '../chat/chat_list_page.dart';

class BuyerMainPage extends StatefulWidget {
  const BuyerMainPage({super.key});

  @override
  State<BuyerMainPage> createState() => _BuyerMainPageState();
}

class _BuyerMainPageState extends State<BuyerMainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const BuyerHomePage(),
    const BuyerRequestsPage(),
    ChatListPage(),
    const BookmarkScreen(),
    const BuyerProfilePage(),
  ];

  final List<String> _titles = [
    "Marketplace",
    "My Requests",
    "Chat",
    "Wishlist",
    "Profile",
  ];

  // Color palette from your brand
  final Color primaryBlue = const Color(0xFF2d8cff);
  final Color softBackground = const Color(0xFFf5f5f7);
  final Color darkText = const Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: softBackground, // Soft light gray
        elevation: 0,
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
        title: Text(
          _titles[_selectedIndex],
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: darkText, // Dark gray text
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Requests"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: "Wishlist"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
