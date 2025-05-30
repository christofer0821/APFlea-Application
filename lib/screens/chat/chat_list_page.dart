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

  Future<String> _getOtherUserName(List<String> participants) async {
    final otherUserId = participants.firstWhere((id) => id != currentUserId);
    final doc = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();
    return doc.data()?['name'] ?? 'User';
  }

  Future<Widget> _buildChatTile(ChatModel chat, BuildContext context) async {
    final otherUserName = await _getOtherUserName(chat.participants);
    final buyerId = chat.participants.first;
    final sellerId = chat.participants.last;

    return ListTile(
      leading: CircleAvatar(child: Text(otherUserName[0])),
      title: Text(otherUserName),
      subtitle: Text(chat.lastMessage),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getUserChats(currentUserId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final chats = snapshot.data!.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();

          if (chats.isEmpty) return const Center(child: Text("No chats yet"));

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
