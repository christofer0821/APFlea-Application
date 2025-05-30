import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_listing.dart';

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("You are not logged in.")),
      );
    }

    final userId = currentUser.uid;
    print("📌 Current User UID: $userId");

    return Scaffold(
      appBar: AppBar(title: const Text("My Listings")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('listings')
            .where('sellerId', isEqualTo: userId)
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
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final doc = listings[index];
              final item = doc.data() as Map<String, dynamic>;

              final isSold = item['isSold'] == true;
              final locationCity = item['locationCity'] ?? '';
              final locationState = item['locationState'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Stack(
                  children: [
                    ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          item['imageUrl'] ?? '',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 60),
                        ),
                      ),
                      title: Text(item['title'] ?? 'Untitled'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("RM ${item['price']} • ${item['quantity']} pcs"),
                          Text("$locationCity, $locationState"),
                          Text("Condition: ${item['condition']} | Quality: ${item['quality']}/10"),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditListingPage(
                                    docId: doc.id,
                                    listing: item,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
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
                                      child: const Text("Delete"),
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
                      ),
                    ),
                    if (isSold)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                          ),
                          child: const Text(
                            "SOLD",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
