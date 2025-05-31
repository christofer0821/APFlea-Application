import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/chat_model.dart';
import 'chat_page.dart';
import 'chat_service.dart';

class ChatListPage extends StatelessWidget {
  ChatListPage({super.key});

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final ChatService _chatService = ChatService();

  final Color backgroundColor = const Color(0xFFF5F5F7);
  final Color textColor = const Color(0xFF333333);
  final Color accentColor = const Color(0xFF2D8CFF);

  Future<String> _getOtherUserName(List<String> participants) async {
    final otherUserId = participants.firstWhere((id) => id != currentUserId);
    final doc = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();
    return doc.data()?['name'] ?? 'User';
  }

  Future<Widget> _buildChatTile(ChatModel chat, BuildContext context) async {
    final otherUserName = await _getOtherUserName(chat.participants);
    final buyerId = chat.participants.first;
    final sellerId = chat.participants.last;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accentColor.withOpacity(0.2),
          child: Text(
            otherUserName[0].toUpperCase(),
            style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(otherUserName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        subtitle: Text(chat.lastMessage, style: TextStyle(color: textColor.withOpacity(0.7))),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatPage(
                chatId: chat.id,
                buyerId: buyerId,
                sellerId: sellerId,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 0, // hide title bar
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getUserChats(currentUserId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final chats = snapshot.data!.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();

          if (chats.isEmpty) {
            return Center(
              child: Text("No chats yet", style: TextStyle(color: textColor)),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return FutureBuilder<Widget>(
                future: _buildChatTile(chat, context),
                builder: (context, snapshot) {
                  return snapshot.hasData ? snapshot.data! : const SizedBox.shrink();
                },
              );
            },
          );
        },
      ),
    );
  }
}
