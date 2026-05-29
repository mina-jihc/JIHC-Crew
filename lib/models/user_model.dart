import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.tasksCompleted,
    required this.crewsJoined,
    required this.createdAt,
    this.photoUrl,
    this.bio,
    this.studentId,
    this.role,
  });

  final String uid;
  final String displayName;
  final String email;
  final int tasksCompleted;
  final int crewsJoined;
  final DateTime createdAt;
  final String? photoUrl;
  final String? bio;
  final String? studentId;
  final String? role;

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    int? tasksCompleted,
    int? crewsJoined,
    DateTime? createdAt,
    String? photoUrl,
    String? bio,
    String? studentId,
    String? role,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      crewsJoined: crewsJoined ?? this.crewsJoined,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      studentId: studentId ?? this.studentId,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{
      'displayName': displayName,
      'email': email,
      'tasksCompleted': tasksCompleted,
      'crewsJoined': crewsJoined,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    if (photoUrl != null) {
      map['photoUrl'] = photoUrl;
    }
    if (bio != null) {
      map['bio'] = bio;
    }
    if (studentId != null) {
      map['studentId'] = studentId;
    }
    if (role != null) {
      map['role'] = role;
    }

    return map;
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      displayName: map['displayName'] as String? ?? 'JIHC Student',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String?,
      studentId: map['studentId'] as String?,
      role: map['role'] as String?,
      tasksCompleted: (map['tasksCompleted'] as num?)?.toInt() ?? 0,
      crewsJoined: (map['crewsJoined'] as num?)?.toInt() ?? 0,
      createdAt: _toDate(map['createdAt']),
    );
  }

  static UserModel fromAuth({
    required String uid,
    required String displayName,
    required String email,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName,
      email: email,
      photoUrl: photoUrl,
      tasksCompleted: 0,
      crewsJoined: 0,
      createdAt: DateTime.now(),
      role: null,
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
