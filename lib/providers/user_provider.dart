import 'package:flutter/foundation.dart';
import '../models/user.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  UserProvider() {
    // Initialize with mock user data
    _user = User(
      id: 'mock-user-id',
      email: 'user@example.com',
      displayName: 'Demo User',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      level: 1,
      currentXp: 0,
      achievements: [],
    );
  }

  User? get user => _user;
  bool get isLoading => _isLoading;

  int getNextLevelThreshold() {
    if (_user == null) return 100;
    return _user!.level * 100;
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock user is already set in constructor
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String displayName) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      _user = User(
        id: 'mock-user-id',
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        level: 1,
        currentXp: 0,
        achievements: [],
      );
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _user = null;
    notifyListeners();
  }

  Future<void> addXp(int amount) async {
    if (_user == null) return;

    int newXp = _user!.currentXp + amount;
    int newLevel = _user!.level;
    
    while (newXp >= getNextLevelThreshold()) {
      newXp -= getNextLevelThreshold();
      newLevel++;
    }

    _user = _user!.copyWith(
      currentXp: newXp,
      level: newLevel,
    );

    notifyListeners();
  }

  Future<void> unlockAchievement(String achievementId) async {
    if (_user == null) return;

    if (!_user!.achievements.contains(achievementId)) {
      _user = _user!.copyWith(
        achievements: [..._user!.achievements, achievementId],
      );
      
      notifyListeners();
    }
  }
} 