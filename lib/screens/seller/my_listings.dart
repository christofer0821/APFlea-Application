import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_listing.dart';

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final backgroundColor = const Color(0xFFF5F5F7);
    final textColor = const Color(0xFF333333);
    final highlightBlue = const Color(0xFF2d8cff);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("You are not logged in.")),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('listings')
            .where('sellerId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("You haven't posted any listings yet."));
          }

          final listings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final doc = listings[index];
              final item = doc.data() as Map<String, dynamic>;

              final isSold = item['isSold'] == true;
              final locationCity = item['locationCity'] ?? '';
              final locationState = item['locationState'] ?? '';

              return Stack(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item['imageUrl'] ?? '',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 60),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] ?? 'Untitled',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "RM ${item['price']} • ${item['quantity']} pcs",
                                  style: TextStyle(color: textColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text("$locationCity, $locationState", style: TextStyle(color: textColor)),
                                const SizedBox(height: 4),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(text: "Condition: ", style: TextStyle(fontWeight: FontWeight.bold)),
                                      TextSpan(text: "${item['condition']}"),
                                    ],
                                  ),
                                  style: TextStyle(color: textColor),
                                ),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(text: "Quality: ", style: TextStyle(fontWeight: FontWeight.bold)),
                                      TextSpan(text: "${item['quality']}/10"),
                                    ],
                                  ),
                                  style: TextStyle(color: textColor),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: highlightBlue,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                                      label: const Text("Edit", style: TextStyle(color: Colors.white)),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EditListingPage(docId: doc.id, listing: item),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                                      label: const Text("Delete", style: TextStyle(color: Colors.white)),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text("Confirm Delete"),
                                            content: const Text("Are you sure you want to delete this listing?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text("Cancel"),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await FirebaseFirestore.instance
                                              .collection('listings')
                                              .doc(doc.id)
                                              .delete();

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Listing deleted")),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  if (isSold)
                    Positioned(
                      top: 8,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "SOLD",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
