import 'package:flutter/foundation.dart';
import '../models/user.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  int _level = 1;
  int _currentXp = 0;
  int _nextLevelXp = 100; // Base XP required for level 2

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
  int get level => _level;
  int get currentXp => _currentXp;
  int get nextLevelXp => _nextLevelXp;

  int getNextLevelThreshold() {
    if (_user == null) return 100;
    return _user!.level * 100;
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Mock sign in - in a real app, this would validate credentials
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
      await Future.delayed(const Duration(milliseconds: 1000));
      
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
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Add the XP amount
    _currentXp += amount;
    
    // Check for level up
    while (_currentXp >= _nextLevelXp) {
      _currentXp -= _nextLevelXp;
      _level++;
      // Increase XP required for next level (using a simple scaling formula)
      _nextLevelXp = (100 * (1.5 * (_level - 1))).round();
    }
    
    // Update the user model if it exists
    if (_user != null) {
      _user = _user!.copyWith(
        level: _level,
        currentXp: _currentXp,
      );
    }
    
    // Notify listeners to update the UI
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