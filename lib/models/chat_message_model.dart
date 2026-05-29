import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.sentAt,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime sentAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }

  factory ChatMessageModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessageModel(
      id: id,
      chatId: map['chatId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? 'JIHC Student',
      message: map['message'] as String? ?? '',
      sentAt: _toDate(map['sentAt']),
    );
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
