import 'package:flutter/material.dart';
import 'seller_home.dart';
import 'add_listing.dart';
import 'my_listings.dart';
import 'seller_dashboard.dart';
import 'seller_profile.dart';
import '../chat/chat_list_page.dart'; // ✅ Add this import

class SellerMainPage extends StatefulWidget {
  const SellerMainPage({super.key});

  @override
  State<SellerMainPage> createState() => _SellerMainPageState();
}

class _SellerMainPageState extends State<SellerMainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const SellerHomePage(),       // 🏠 Home
    const AddListingPage(),       // ➕ Add
    const MyListingsPage(),       // 📦 Listings
    ChatListPage(),               // 💬 Chat (non-const because async is inside)
    const SellerDashboardPage(),  // 📊 Dashboard
    const SellerProfilePage(),    // 👤 Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Needed for >4 items
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: "Add"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Listings"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"), // ✅ New
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
