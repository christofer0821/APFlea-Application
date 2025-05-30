import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/chat_model.dart';
import 'chat_service.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String buyerId;
  final String sellerId;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.buyerId,
    required this.sellerId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Future<String> _getUserName(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data()?['name'] ?? 'User';
  }

  Future<Widget> _buildMessageTile(MessageModel message) async {
    final isMe = message.senderId == currentUserId;
    final name = await _getUserName(message.senderId);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isMe ? Colors.white : Colors.black12,
              child: Text(name[0]),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  message.text,
                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _chatService.sendMessage(
      chatId: widget.chatId,
      senderId: currentUserId,
      text: text,
    );

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessageStream(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs
                    .map((doc) => MessageModel.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  reverse: false,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return FutureBuilder<Widget>(
                      future: _buildMessageTile(message),
                      builder: (context, snapshot) {
                        return snapshot.hasData ? snapshot.data! : const SizedBox.shrink();
                      },
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Colors.deepPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
