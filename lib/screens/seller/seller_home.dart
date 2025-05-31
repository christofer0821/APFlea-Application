import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerHomePage extends StatelessWidget {
  const SellerHomePage({super.key});

  Future<void> approveRequest(String requestId, String listingId) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.collection('purchase_requests').doc(requestId).update({'status': 'approved'});
    await firestore.collection('listings').doc(listingId).update({'isSold': true});

    final pendingRequests = await firestore
        .collection('purchase_requests')
        .where('listingId', isEqualTo: listingId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (final doc in pendingRequests.docs) {
      if (doc.id != requestId) {
        await doc.reference.update({'status': 'rejected'});
      }
    }
  }

  Future<void> rejectRequest(String requestId) async {
    await FirebaseFirestore.instance.collection('purchase_requests').doc(requestId).update({'status': 'rejected'});
  }

  Future<Map<String, dynamic>?> fetchListing(String listingId) async {
    final doc = await FirebaseFirestore.instance.collection('listings').doc(listingId).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final sellerId = FirebaseAuth.instance.currentUser?.uid;

    final Color backgroundColor = const Color(0xFFF5F5F7);
    final Color textColor = const Color(0xFF333333);
    final Color highlightColor = const Color(0xFF2d8cff);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ListView(
            children: [
              
              // 📢 ANNOUNCEMENTS
              Text("📢 Announcements", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('announcements')
                    .where('target', whereIn: ['seller', 'both'])
                    .orderBy('createdAt', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Text("No announcements", style: TextStyle(color: Colors.grey[600]));
                  }
                  return Column(
                    children: snapshot.data!.docs.map((doc) {
                      final ann = doc.data() as Map<String, dynamic>;
                      return Card(
                        color: Colors.amber.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(ann['title'] ?? "No Title", style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(ann['message'] ?? ""),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 32),

              // 📨 PURCHASE REQUESTS
              Text("🛒 Purchase Requests", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('purchase_requests')
                    .where('sellerId', isEqualTo: sellerId)
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Text("No requests at the moment.", style: TextStyle(color: Colors.grey[600]));
                  }

                  final requests = snapshot.data!.docs;

                  return Column(
                    children: requests.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return FutureBuilder<Map<String, dynamic>?>(
                        future: fetchListing(data['listingId']),
                        builder: (context, listingSnapshot) {
                          if (!listingSnapshot.hasData) {
                            return const SizedBox();
                          }

                          final listing = listingSnapshot.data!;
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      listing['imageUrl'] != null
                                          ? Image.network(listing['imageUrl'], width: 60, height: 60, fit: BoxFit.cover)
                                          : const Icon(Icons.image, size: 60),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          listing['title'] ?? 'No Title',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text("Buyer ID: ${data['buyerId']}", style: const TextStyle(fontSize: 12)),
                                  Text("Price: RM ${listing['price']}", style: const TextStyle(fontSize: 12)),
                                  Text("Qty: ${listing['quantity']}", style: const TextStyle(fontSize: 12)),
                                  Text("Location: ${listing['locationCity']}, ${listing['locationState']}", style: const TextStyle(fontSize: 12)),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: highlightColor,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => approveRequest(doc.id, data['listingId']),
                                        child: const Text("Approve"),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => rejectRequest(doc.id),
                                        child: const Text("Reject"),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
