import 'package:cloud_firestore/cloud_firestore.dart';

class CrewModel {
  const CrewModel({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.members,
    required this.category,
    required this.createdAt,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final String creatorId;
  final List<String> members;
  final String category;
  final DateTime createdAt;
  final String? imageUrl;

  CrewModel copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    List<String>? members,
    String? category,
    DateTime? createdAt,
    String? imageUrl,
  }) {
    return CrewModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      members: members ?? this.members,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'members': members,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
    };
  }

  factory CrewModel.fromMap(String id, Map<String, dynamic> map) {
    return CrewModel(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      creatorId: map['creatorId'] as String? ?? '',
      members: List<String>.from(
        map['members'] as List<dynamic>? ?? <dynamic>[],
      ),
      category: map['category'] as String? ?? 'Community',
      createdAt: _toDate(map['createdAt']),
      imageUrl: map['imageUrl'] as String?,
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
