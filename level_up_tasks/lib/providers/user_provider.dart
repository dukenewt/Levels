import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  Map<String, dynamic>? _userData;

  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userData => _userData;

  UserProvider() {
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      if (user != null) {
        _loadUserData();
      } else {
        _userData = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData() async {
    if (_currentUser != null) {
      final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      _userData = doc.data();
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String displayName) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await userCredential.user?.updateDisplayName(displayName);
      
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'displayName': displayName,
        'email': email,
        'level': 1,
        'xp': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      await _loadUserData();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      if (_currentUser != null) {
        if (displayName != null) {
          await _currentUser!.updateDisplayName(displayName);
        }
        if (photoURL != null) {
          await _currentUser!.updatePhotoURL(photoURL);
        }
        await _loadUserData();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addXP(int amount) async {
    if (_currentUser != null) {
      final currentXP = _userData?['xp'] ?? 0;
      final currentLevel = _userData?['level'] ?? 1;
      final newXP = currentXP + amount;
      final xpNeededForNextLevel = currentLevel * 100;
      
      int newLevel = currentLevel;
      if (newXP >= xpNeededForNextLevel) {
        newLevel = currentLevel + 1;
      }

      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'xp': newXP,
        'level': newLevel,
      });

      await _loadUserData();
    }
  }
} 