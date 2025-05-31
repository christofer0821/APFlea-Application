import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'item_detail.dart';

class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  final Color backgroundColor = const Color(0xFFF5F5F7);
  final Color textColor = const Color(0xFF333333);

  Stream<List<Map<String, dynamic>>> getBookmarkedListings() async* {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) yield [];

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final bookmarks = List<String>.from(userDoc.data()?['bookmarks'] ?? []);

    if (bookmarks.isEmpty) {
      yield [];
      return;
    }

    final snapshots = await Future.wait(bookmarks.map((id) =>
        FirebaseFirestore.instance.collection('listings').doc(id).get()));

    yield snapshots
        .where((doc) => doc.exists)
        .map((doc) => {'id': doc.id, ...?doc.data()})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 0, // hide AppBar title
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getBookmarkedListings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final listings = snapshot.data ?? [];

          if (listings.isEmpty) {
            return Center(
              child: Text(
                "No bookmarked items found.",
                style: TextStyle(color: textColor),
              ),
            );
          }

          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final item = listings[index];
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: item['imageUrl'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item['imageUrl'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.image_not_supported),
                  title: Text(item['title'] ?? 'No Title', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("RM ${item['price']} • ${item['quantity']} pcs", style: TextStyle(color: textColor)),
                      Text("${item['locationCity']}, ${item['locationState']}", style: TextStyle(color: textColor)),
                      Text("Condition: ${item['condition']} | Quality: ${item['quality']}/10", style: TextStyle(color: textColor)),
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
