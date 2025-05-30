import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/chat_page.dart'; // ✅ make sure this path is correct in your project

class ItemDetailPage extends StatelessWidget {
  final Map<String, dynamic> item;

  const ItemDetailPage({super.key, required this.item});

  Future<void> _sendBuyRequest(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to buy")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('purchase_requests').add({
        'listingId': item['id'],
        'listingTitle': item['title'],
        'buyerId': user.uid,
        'sellerId': item['sellerId'],
        'status': 'pending',
        'timestamp': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Purchase request sent!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final sellerId = item['sellerId'];
    final chatId = currentUser.uid.hashCode <= sellerId.hashCode
        ? "${currentUser.uid}_$sellerId"
        : "${sellerId}_${currentUser.uid}";

    return Scaffold(
      appBar: AppBar(title: Text(item['title'] ?? "Item Detail")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['imageUrl'] != null)
              Center(
                child: Image.network(
                  item['imageUrl'],
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),

            Text(item['title'] ?? "", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("RM ${item['price']}", style: const TextStyle(fontSize: 18, color: Colors.green)),

            const Divider(height: 24),

            Text("Description", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(item['description'] ?? "-"),
            const SizedBox(height: 16),

            Text("Location", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text("${item['locationCity']}, ${item['locationState']}"),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Condition: ${item['condition']}"),
                Text("Quality: ${item['quality']}/10"),
                Text("Qty: ${item['quantity']}"),
              ],
            ),
            const SizedBox(height: 24),

            Center(
              child: ElevatedButton.icon(
                onPressed: () => _sendBuyRequest(context),
                icon: const Icon(Icons.shopping_cart_checkout),
                label: const Text("Buy"),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        chatId: chatId,
                        buyerId: currentUser.uid,
                        sellerId: sellerId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat),
                label: const Text("Chat Seller"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
