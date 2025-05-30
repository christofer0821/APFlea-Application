import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'item_detail.dart';

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
        title: const Text("Marketplace"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('listings')
            .where('approved', isEqualTo: true) // ✅ Must be boolean
            .where('isSold', isEqualTo: false)   // ✅ Must match field in Firestore
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No listings available"));
          }

          final listings = snapshot.data!.docs;

          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final doc = listings[index];
              final item = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: item['imageUrl'] != null
                      ? Image.network(
                          item['imageUrl'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image_not_supported),
                  title: Text(item['title'] ?? 'No Title'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("RM ${item['price']} • ${item['quantity']} pcs"),
                      Text("${item['locationCity']}, ${item['locationState']}"),
                      Text("Condition: ${item['condition']} | Quality: ${item['quality']}/10"),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemDetailPage(item: item),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
