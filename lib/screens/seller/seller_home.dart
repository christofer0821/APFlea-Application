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
              Text("Seller Dashboard", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 24),

              // 📢 ANNOUNCEMENTS
              Text("📢 Announcements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
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
              Text("🛒 Purchase Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
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
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                        child: ListTile(
                          title: Text("Listing: ${data['listingTitle'] ?? 'Unknown'}"),
                          subtitle: Text("Buyer ID: ${data['buyerId']}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.check_circle, color: highlightColor),
                                onPressed: () => approveRequest(doc.id, data['listingId']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => rejectRequest(doc.id),
                              ),
                            ],
                          ),
                        ),
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
