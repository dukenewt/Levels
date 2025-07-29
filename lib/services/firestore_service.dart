import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_user;

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<app_user.User?> getUser(String uid) async {
    final snapshot = await _db.collection('users').doc(uid).get();
    if (snapshot.exists) {
      return app_user.User.fromJson(snapshot.data()!);
    }
    return null;
  }

  Future<void> setUser(app_user.User user) {
    return _db.collection('users').doc(user.id).set(user.toJson());
  }

  Future<void> updateUserProfilePicture(String uid, String url) {
    return _db.collection('users').doc(uid).update({'profilePictureUrl': url});
  }

  Future<void> createUserFromFirebase(String uid, String? displayName, String? email) async {
    final now = DateTime.now();
    final user = app_user.User(
      id: uid,
      displayName: displayName ?? 'No Name',
      email: email ?? '',
      createdAt: now,
      lastLoginAt: now,
      currentXp: 0,
      level: 1,
    );
    await setUser(user);
  }
} 