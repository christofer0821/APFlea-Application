import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/chat_page.dart';

class ItemDetailPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemDetailPage({super.key, required this.item});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  bool isBookmarked = false;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final bookmarks = List<String>.from(doc.data()?['bookmarks'] ?? []);
    setState(() => isBookmarked = bookmarks.contains(widget.item['id']));
  }

  Future<void> _toggleBookmark() async {
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);
    final doc = await docRef.get();
    List<String> bookmarks = List<String>.from(doc.data()?['bookmarks'] ?? []);

    if (bookmarks.contains(widget.item['id'])) {
      bookmarks.remove(widget.item['id']);
    } else {
      bookmarks.add(widget.item['id']);
    }

    await docRef.update({'bookmarks': bookmarks});
    setState(() => isBookmarked = !isBookmarked);
  }

  Future<void> _sendBuyRequest(BuildContext context) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to send a request")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('purchase_requests').add({
        'listingId': widget.item['id'],
        'listingTitle': widget.item['title'],
        'category': widget.item['category'] ?? 'Uncategorized',
        'buyerId': user!.uid,
        'sellerId': widget.item['sellerId'],
        'status': 'pending',
        'createdAt': DateTime.now(),
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
    final sellerId = widget.item['sellerId'];
    final chatId = currentUser.uid.hashCode <= sellerId.hashCode
        ? "${currentUser.uid}_$sellerId"
        : "${sellerId}_${currentUser.uid}";

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB), // ← Updated background color
      appBar: AppBar(
        title: Text(widget.item['title'] ?? "Item Detail"),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
              color: isBookmarked ? Colors.blue : null,
            ),
            onPressed: _toggleBookmark,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.item['imageUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.item['imageUrl'],
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),

            Text(
              widget.item['title'] ?? "No Title",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            Text(
              "Category: ${widget.item['category'] ?? 'Uncategorized'}",
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),

            Text(
              "RM ${widget.item['price']}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),

            const Divider(height: 30, thickness: 1.5),

            Text("Description", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(widget.item['description'] ?? "-", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            Text("Location", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text("${widget.item['locationCity'] ?? '-'}, ${widget.item['locationState'] ?? '-'}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Condition: ${widget.item['condition'] ?? '-'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Quality: ${widget.item['quality']}/10", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Qty: ${widget.item['quantity']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendBuyRequest(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 108, 228),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: const Text("Buy Now"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(width: 3, color: Color.fromARGB(255, 0, 108, 228)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: const Color.fromARGB(255, 0, 108, 228),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    icon: const Icon(Icons.chat),
                    label: const Text("Chat Seller"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
