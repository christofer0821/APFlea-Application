import 'package:flutter/material.dart';
import 'seller_home.dart';
import 'add_listing.dart';
import 'my_listings.dart';
import 'seller_dashboard.dart';
import 'seller_profile.dart';
import '../chat/chat_list_page.dart';

class SellerMainPage extends StatefulWidget {
  const SellerMainPage({super.key});

  @override
  State<SellerMainPage> createState() => _SellerMainPageState();
}

class _SellerMainPageState extends State<SellerMainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const SellerHomePage(),
    const AddListingPage(),
    const MyListingsPage(),
    ChatListPage(),
    const SellerDashboardPage(),
    const SellerProfilePage(),
  ];

  final List<String> _titles = [
    "Seller",
    "Add Item",
    "My Listings",
    "Chats",
    "Dashboard",
    "Profile",
  ];

  // Match Buyer's theme
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
        backgroundColor: softBackground,
        elevation: 0,
        leadingWidth: 120,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: SafeArea(
            child: Image.asset(
              'assets/logo.png', // ✅ Use same path as buyer
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          _titles[_selectedIndex],
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: darkText,
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
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: "Add"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Listings"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
