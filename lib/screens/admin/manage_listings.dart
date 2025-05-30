import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageListingsPage extends StatelessWidget {
  const ManageListingsPage({super.key});

  Future<void> _approveListing(String docId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('listings').doc(docId).update({
        'approved': true,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Listing approved")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error approving listing: $e")),
      );
    }
  }

  Future<void> _rejectListing(String docId, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reject Listing"),
        content: const Text("Are you sure you want to reject/delete this listing?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('listings').doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Listing deleted")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pending Listings")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('listings')
            .where('approved', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No pending listings."));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: data['imageUrl'] != null
                      ? Image.network(data['imageUrl'], width: 60, height: 60, fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported),
                  title: Text(data['title'] ?? 'No Title'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("RM ${data['price']} • ${data['quantity']} pcs"),
                      Text("${data['locationCity']}, ${data['locationState']}"),
                      Text("Seller ID: ${data['sellerId']}"),
                    ],
                  ),
                  trailing: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _approveListing(doc.id, context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _rejectListing(doc.id, context),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
