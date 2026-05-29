import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  const ChatRoomModel({
    required this.id,
    required this.title,
    required this.category,
    required this.createdAt,
    required this.createdBy,
    required this.memberIds,
    required this.isPreset,
  });

  final String id;
  final String title;
  final String category;
  final DateTime createdAt;
  final String createdBy;
  final List<String> memberIds;
  final bool isPreset;

  int get memberCount => memberIds.length;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'memberIds': memberIds,
      'isPreset': isPreset,
    };
  }

  factory ChatRoomModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatRoomModel(
      id: id,
      title: map['title'] as String? ?? 'Chat room',
      category: map['category'] as String? ?? 'General',
      createdAt: _toDate(map['createdAt']),
      createdBy: map['createdBy'] as String? ?? '',
      memberIds: (map['memberIds'] as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .toList(),
      isPreset: map['isPreset'] as bool? ?? false,
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
