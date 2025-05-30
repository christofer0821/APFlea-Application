import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime? updatedAt;

  ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.updatedAt,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }
}

class MessageModel {
  final String id;
  final String text;
  final String senderId;
  final DateTime? timestamp;

  MessageModel({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
