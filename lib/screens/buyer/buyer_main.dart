import 'package:flutter/material.dart';
import 'buyer_home.dart';
import 'bookmark_screen.dart';
import 'buyer_profile.dart';
import 'buyer_requests_page.dart'; // ✅ NEW
import '../chat/chat_list_page.dart'; // ✅ REPLACE old chat import

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
    ChatListPage(), // ✅ Actual working chat screen
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
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
