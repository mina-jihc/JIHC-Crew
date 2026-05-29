import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:jihc_volunteers_app/core/constants/app_constants.dart';
import 'package:jihc_volunteers_app/models/chat_message_model.dart';
import 'package:jihc_volunteers_app/models/chat_room_model.dart';
import 'package:jihc_volunteers_app/models/crew_model.dart';
import 'package:jihc_volunteers_app/models/task_model.dart';
import 'package:jihc_volunteers_app/models/user_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  bool get _isReady => Firebase.apps.isNotEmpty;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _firestore.collection('tasks');
  CollectionReference<Map<String, dynamic>> get _crews =>
      _firestore.collection('crews');
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection('chats');

  Stream<List<TaskModel>> getTasksStream() {
    if (!_isReady) {
      return Stream<List<TaskModel>>.value(const <TaskModel>[]);
    }
    return _tasks.snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      final List<TaskModel> tasks = snapshot.docs.map((
        QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
        return TaskModel.fromMap(doc.id, doc.data());
      }).toList();
      tasks.sort((TaskModel a, TaskModel b) => a.date.compareTo(b.date));
      return tasks;
    });
  }

  Stream<List<TaskModel>> getMyTasksStream(String uid) {
    if (!_isReady || uid.isEmpty) {
      return Stream<List<TaskModel>>.value(const <TaskModel>[]);
    }
    return _tasks.where('volunteers', arrayContains: uid).snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      final List<TaskModel> tasks = snapshot.docs.map((
        QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
        return TaskModel.fromMap(doc.id, doc.data());
      }).toList();
      tasks.sort((TaskModel a, TaskModel b) => a.date.compareTo(b.date));
      return tasks;
    });
  }

  Stream<List<TaskModel>> getMyCreatedTasksStream(String uid) {
    if (!_isReady || uid.isEmpty) {
      return Stream<List<TaskModel>>.value(const <TaskModel>[]);
    }
    return _tasks.where('creatorId', isEqualTo: uid).snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      final List<TaskModel> tasks = snapshot.docs.map((
        QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
        return TaskModel.fromMap(doc.id, doc.data());
      }).toList();
      tasks.sort((TaskModel a, TaskModel b) => a.date.compareTo(b.date));
      return tasks;
    });
  }

  Stream<TaskModel?> getTaskStream(String taskId) {
    if (!_isReady || taskId.isEmpty) {
      return Stream<TaskModel?>.value(null);
    }
    return _tasks.doc(taskId).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> snapshot,
    ) {
      final Map<String, dynamic>? data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return TaskModel.fromMap(snapshot.id, data);
    });
  }

  Future<void> createTask(TaskModel task) async {
    _guardReady();
    await _ensureRole(
      AppConstants.administratorRole,
      'Only administrators can create tasks.',
    );
    final DocumentReference<Map<String, dynamic>> doc = _tasks.doc();
    await doc.set(task.copyWith(id: doc.id).toMap());
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    _guardReady();
    await _ensureRole(
      AppConstants.administratorRole,
      'Only administrators can edit tasks.',
    );
    await _tasks.doc(taskId).update(data);
  }

  Future<void> deleteTask(String taskId) async {
    _guardReady();
    await _ensureRole(
      AppConstants.administratorRole,
      'Only administrators can delete tasks.',
    );
    await _tasks.doc(taskId).delete();
  }

  Future<void> joinTask(String taskId, String uid) async {
    _guardReady();
    await _ensureRole(
      AppConstants.volunteerRole,
      'Only volunteers can apply to tasks.',
    );
    await _tasks.doc(taskId).update(<String, dynamic>{
      'volunteers': FieldValue.arrayUnion(<String>[uid]),
    });
  }

  Future<void> leaveTask(String taskId, String uid) async {
    _guardReady();
    await _ensureRole(
      AppConstants.volunteerRole,
      'Only volunteers can apply to tasks.',
    );
    await _tasks.doc(taskId).update(<String, dynamic>{
      'volunteers': FieldValue.arrayRemove(<String>[uid]),
    });
  }

  Future<void> toggleTaskLike({
    required String taskId,
    required String uid,
    required bool isLiked,
  }) async {
    _guardReady();
    await _tasks.doc(taskId).update(<String, dynamic>{
      'likedBy': isLiked
          ? FieldValue.arrayRemove(<String>[uid])
          : FieldValue.arrayUnion(<String>[uid]),
      'likesCount': FieldValue.increment(isLiked ? -1 : 1),
    });
  }

  Stream<List<CrewModel>> getCrewsStream() {
    if (!_isReady) {
      return Stream<List<CrewModel>>.value(const <CrewModel>[]);
    }
    return _crews.snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      final List<CrewModel> crews = snapshot.docs.map((
        QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
        return CrewModel.fromMap(doc.id, doc.data());
      }).toList();
      crews.sort(
        (CrewModel a, CrewModel b) => b.createdAt.compareTo(a.createdAt),
      );
      return crews;
    });
  }

  Stream<CrewModel?> getCrewStream(String crewId) {
    if (!_isReady || crewId.isEmpty) {
      return Stream<CrewModel?>.value(null);
    }
    return _crews.doc(crewId).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> snapshot,
    ) {
      final Map<String, dynamic>? data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return CrewModel.fromMap(snapshot.id, data);
    });
  }

  Future<void> createCrew(CrewModel crew) async {
    _guardReady();
    final DocumentReference<Map<String, dynamic>> doc = _crews.doc();
    await doc.set(crew.copyWith(id: doc.id).toMap());
  }

  Future<void> updateCrew(String crewId, Map<String, dynamic> data) async {
    _guardReady();
    await _crews.doc(crewId).update(data);
  }

  Future<void> deleteCrew(String crewId) async {
    _guardReady();
    await _crews.doc(crewId).delete();
  }

  Future<void> joinCrew(String crewId, String uid) async {
    _guardReady();
    await _crews.doc(crewId).update(<String, dynamic>{
      'members': FieldValue.arrayUnion(<String>[uid]),
    });
  }

  Future<void> leaveCrew(String crewId, String uid) async {
    _guardReady();
    await _crews.doc(crewId).update(<String, dynamic>{
      'members': FieldValue.arrayRemove(<String>[uid]),
    });
  }

  Stream<UserModel?> getUserStream(String uid) {
    if (!_isReady || uid.isEmpty) {
      return Stream<UserModel?>.value(null);
    }
    return _users.doc(uid).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> snapshot,
    ) {
      final Map<String, dynamic>? data = snapshot.data();
      if (snapshot.exists && data != null) {
        return UserModel.fromMap(snapshot.id, data);
      }
      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null && firebaseUser.uid == uid) {
        return UserModel.fromAuth(
          uid: firebaseUser.uid,
          displayName: firebaseUser.displayName ?? 'JIHC Student',
          email: firebaseUser.email ?? '',
          photoUrl: firebaseUser.photoURL,
        );
      }
      return null;
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    _guardReady();
    await _users.doc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> ensureUserDocument(User? firebaseUser) async {
    if (!_isReady || firebaseUser == null) {
      return;
    }
    final DocumentReference<Map<String, dynamic>> doc = _users.doc(
      firebaseUser.uid,
    );
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await doc.get();
    if (snapshot.exists) {
      return;
    }

    final UserModel userModel = UserModel.fromAuth(
      uid: firebaseUser.uid,
      displayName: firebaseUser.displayName ?? 'JIHC Student',
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL,
    );
    await doc.set(userModel.toMap());
  }

  Future<UserModel?> getUserProfile(String uid) async {
    if (!_isReady || uid.isEmpty) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _users
        .doc(uid)
        .get();
    final Map<String, dynamic>? data = snapshot.data();
    if (snapshot.exists && data != null) {
      return UserModel.fromMap(snapshot.id, data);
    }

    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser != null && firebaseUser.uid == uid) {
      return UserModel.fromAuth(
        uid: firebaseUser.uid,
        displayName: firebaseUser.displayName ?? 'JIHC Student',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
      );
    }
    return null;
  }

  Future<String?> getUserRole(String uid) async {
    final UserModel? user = await getUserProfile(uid);
    return user?.role;
  }

  Future<void> setUserRole(String uid, String role) async {
    _guardReady();
    if (role != AppConstants.volunteerRole &&
        role != AppConstants.administratorRole) {
      throw ArgumentError('Unsupported role: $role');
    }
    await _users.doc(uid).set(
      <String, dynamic>{'role': role},
      SetOptions(merge: true),
    );
  }

  Stream<List<UserModel>> getLeaderboardStream() {
    if (!_isReady) {
      return Stream<List<UserModel>>.value(const <UserModel>[]);
    }

    return _users
        .orderBy('tasksCompleted', descending: true)
        .limit(20)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            return UserModel.fromMap(doc.id, doc.data());
          })
          .toList();
    });
  }

  Future<void> ensureChatRoom({
    required String chatId,
    required String title,
    required String category,
  }) async {
    _guardReady();
    await _chats.doc(chatId).set(
      <String, dynamic>{
        'title': title,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': '',
        'memberIds': <String>[],
        'isPreset': true,
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<ChatRoomModel>> getCustomChatRoomsStream() {
    if (!_isReady) {
      return Stream<List<ChatRoomModel>>.value(const <ChatRoomModel>[]);
    }

    return _chats.where('isPreset', isEqualTo: false).snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      final List<ChatRoomModel> rooms = snapshot.docs.map((
        QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
        return ChatRoomModel.fromMap(doc.id, doc.data());
      }).toList();
      rooms.sort(
        (ChatRoomModel a, ChatRoomModel b) => b.createdAt.compareTo(a.createdAt),
      );
      return rooms;
    });
  }

  Stream<ChatRoomModel?> getChatRoomStream(String chatId) {
    if (!_isReady || chatId.isEmpty) {
      return Stream<ChatRoomModel?>.value(null);
    }

    return _chats.doc(chatId).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> snapshot,
    ) {
      final Map<String, dynamic>? data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return ChatRoomModel.fromMap(snapshot.id, data);
    });
  }

  Stream<List<ChatMessageModel>> getChatMessagesStream(String chatId) {
    if (!_isReady || chatId.isEmpty) {
      return Stream<List<ChatMessageModel>>.value(const <ChatMessageModel>[]);
    }

    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            return ChatMessageModel.fromMap(doc.id, doc.data());
          })
          .toList();
    });
  }

  Future<void> sendChatMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    _guardReady();
    await _chats.doc(chatId).collection('messages').add(<String, dynamic>{
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message.trim(),
      'sentAt': Timestamp.now(),
    });
  }

  Future<String> createCustomChatRoom({
    required String title,
    required String category,
    required String creatorId,
    required List<String> memberIds,
  }) async {
    _guardReady();
    await _ensureRole(
      AppConstants.administratorRole,
      'Only administrators can create new chats.',
    );
    final DocumentReference<Map<String, dynamic>> doc = _chats.doc();
    final Set<String> uniqueMemberIds = <String>{
      creatorId,
      ...memberIds.where((String value) => value.isNotEmpty),
    };

    await doc.set(
      ChatRoomModel(
        id: doc.id,
        title: title.trim(),
        category: category,
        createdAt: DateTime.now(),
        createdBy: creatorId,
        memberIds: uniqueMemberIds.toList(),
        isPreset: false,
      ).toMap(),
    );
    return doc.id;
  }

  Future<List<String>> findUserIdsByEmails(List<String> emails) async {
    _guardReady();

    final Set<String> uniqueUserIds = <String>{};
    for (final String rawEmail in emails) {
      final String email = rawEmail.trim().toLowerCase();
      if (email.isEmpty) {
        continue;
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot = await _users
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        uniqueUserIds.add(snapshot.docs.first.id);
      }
    }

    return uniqueUserIds.toList();
  }

  Future<void> addMembersToChatRoom({
    required String chatId,
    required List<String> memberIds,
  }) async {
    _guardReady();
    await _ensureRole(
      AppConstants.administratorRole,
      'Only administrators can add members to chats.',
    );
    if (memberIds.isEmpty) {
      return;
    }

    await _chats.doc(chatId).set(
      <String, dynamic>{
        'memberIds': FieldValue.arrayUnion(
          memberIds.where((String value) => value.isNotEmpty).toList(),
        ),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteChatMessage({
    required String chatId,
    required String messageId,
  }) async {
    _guardReady();
    await _ensureRole(
      AppConstants.administratorRole,
      'Only administrators can delete chat messages.',
    );
    await _chats.doc(chatId).collection('messages').doc(messageId).delete();
  }

  void _guardReady() {
    if (!_isReady) {
      throw StateError('Firebase is not configured yet.');
    }
  }

  Future<void> _ensureRole(String role, String errorMessage) async {
    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw StateError('Sign in first to continue.');
    }

    final UserModel? profile = await getUserProfile(firebaseUser.uid);
    if (profile?.role != role) {
      throw StateError(errorMessage);
    }
  }
}
