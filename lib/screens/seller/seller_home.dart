import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerHomePage extends StatelessWidget {
  const SellerHomePage({super.key});

  Future<void> approveRequest(String requestId, String listingId) async {
    final firestore = FirebaseFirestore.instance;

    // 1. Approve the selected request
    await firestore.collection('purchase_requests').doc(requestId).update({
      'status': 'approved',
    });

    // 2. Mark the listing as sold
    await firestore.collection('listings').doc(listingId).update({
      'isSold': true,
    });

    // 3. Auto-reject other pending requests for the same listing
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
    await FirebaseFirestore.instance
        .collection('purchase_requests')
        .doc(requestId)
        .update({'status': 'rejected'});
  }

  @override
  Widget build(BuildContext context) {
    final sellerId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Home'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📢 ANNOUNCEMENTS
            const Text("Announcements", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text("No announcements");
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final ann = doc.data() as Map<String, dynamic>;
                    return Card(
                      color: Colors.amber.shade100,
                      child: ListTile(
                        title: Text(ann['title'] ?? "No Title"),
                        subtitle: Text(ann['message'] ?? ""),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // 📨 PURCHASE REQUESTS
            const Text("Purchase Requests", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('purchase_requests')
                  .where('sellerId', isEqualTo: sellerId)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text("No requests at the moment.");
                final requests = snapshot.data!.docs;

                return Column(
                  children: requests.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text("Listing: ${data['listingTitle'] ?? 'Unknown'}"),
                        subtitle: Text("Buyer ID: ${data['buyerId']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => approveRequest(doc.id, data['listingId']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
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
    );
  }
}
