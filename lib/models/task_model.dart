import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.creatorId,
    required this.creatorName,
    required this.date,
    required this.location,
    required this.maxVolunteers,
    required this.volunteers,
    required this.status,
    required this.createdAt,
    this.imageUrl,
    this.likesCount = 0,
    this.likedBy = const <String>[],
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String creatorId;
  final String creatorName;
  final DateTime date;
  final String location;
  final int maxVolunteers;
  final List<String> volunteers;
  final String status;
  final DateTime createdAt;
  final String? imageUrl;
  final int likesCount;
  final List<String> likedBy;

  bool get isFull => volunteers.length >= maxVolunteers;
  int get spotsLeft => maxVolunteers - volunteers.length;

  bool isLikedBy(String uid) => likedBy.contains(uid);

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? creatorId,
    String? creatorName,
    DateTime? date,
    String? location,
    int? maxVolunteers,
    List<String>? volunteers,
    String? status,
    DateTime? createdAt,
    String? imageUrl,
    int? likesCount,
    List<String>? likedBy,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      date: date ?? this.date,
      location: location ?? this.location,
      maxVolunteers: maxVolunteers ?? this.maxVolunteers,
      volunteers: volunteers ?? this.volunteers,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'category': category,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'date': Timestamp.fromDate(date),
      'location': location,
      'maxVolunteers': maxVolunteers,
      'volunteers': volunteers,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
      'likesCount': likesCount,
      'likedBy': likedBy,
    };
  }

  factory TaskModel.fromMap(String id, Map<String, dynamic> map) {
    return TaskModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Community',
      creatorId: map['creatorId'] as String? ?? '',
      creatorName: map['creatorName'] as String? ?? 'Volunteer',
      date: _toDate(map['date']),
      location: map['location'] as String? ?? 'JIHC Campus',
      maxVolunteers: (map['maxVolunteers'] as num?)?.toInt() ?? 0,
      volunteers: List<String>.from(
        map['volunteers'] as List<dynamic>? ?? <dynamic>[],
      ),
      status: map['status'] as String? ?? 'open',
      createdAt: _toDate(map['createdAt']),
      imageUrl: map['imageUrl'] as String?,
      likesCount: (map['likesCount'] as num?)?.toInt() ?? 0,
      likedBy: List<String>.from(
        map['likedBy'] as List<dynamic>? ?? <dynamic>[],
      ),
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
