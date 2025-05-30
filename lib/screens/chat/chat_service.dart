import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return ids.join('_');
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final messageData = {
      'text': text,
      'senderId': senderId,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('chats').doc(chatId).collection('messages').add(messageData);

    await _firestore.collection('chats').doc(chatId).set({
      'participants': chatId.split('_'),
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getMessageStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  Stream<QuerySnapshot> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }
}
