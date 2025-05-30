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

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final listings = await FirebaseFirestore.instance
        .collection('listings')
        .where('sellerId', isEqualTo: uid)
        .get();

    final pending = listings.docs.where((doc) => !(doc.data()['approved'] ?? true)).length;

    setState(() {
      totalListings = listings.size;
      pendingListings = pending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seller Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildStatCard("Total Listings", totalListings),
                const SizedBox(width: 16),
                _buildStatCard("Pending Approval", pendingListings),
              ],
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Tips from Admin", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            const Text(
              "Ensure your listings have clear titles, high-quality images, and accurate pricing to increase approval and attract buyers.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text("$count", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
