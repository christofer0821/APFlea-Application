import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  int totalListings = 0;
  int pendingListings = 0;
  int soldListings = 0;
  double totalEarnings = 0.0;

  final backgroundColor = const Color(0xFFF5F5F7);
  final textColor = const Color(0xFF333333);
  final highlightBlue = const Color(0xFF2d8cff);

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final listingsSnapshot = await FirebaseFirestore.instance
        .collection('listings')
        .where('sellerId', isEqualTo: uid)
        .get();

    int soldCount = 0;
    double earnings = 0.0;
    int pendingCount = 0;

    for (var doc in listingsSnapshot.docs) {
      final data = doc.data();
      if (!(data['approved'] ?? true)) pendingCount++;
      if (data['isSold'] == true) {
        soldCount++;
        earnings += (data['price'] ?? 0) * (data['quantity'] ?? 1);
      }
    }

    setState(() {
      totalListings = listingsSnapshot.size;
      pendingListings = pendingCount;
      soldListings = soldCount;
      totalEarnings = earnings;
    });
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Seller Dashboard",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildStatCard("Total Listings", totalListings),
                const SizedBox(width: 12),
                _buildStatCard("Pending Approval", pendingListings),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard("Sold Listings", soldListings),
                const SizedBox(width: 12),
                _buildStatCard("Total Earnings", totalEarnings.toStringAsFixed(2), prefix: "RM "),
              ],
            ),
            const SizedBox(height: 32),
            const Text("Tips from Admin",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333))),
            const SizedBox(height: 8),
            const Text(
              "Ensure your listings have clear titles, high-quality images, and accurate pricing to increase approval and attract buyers.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, dynamic value, {String prefix = ""}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
            const SizedBox(height: 8),
            Text("$prefix$value",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: highlightBlue)),
          ],
        ),
      ),
    );
  }
}
