import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/user_rank.dart';
import '../widgets/level_up_overlay.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  int _level = 1;
  int _currentXp = 0;
  int _nextLevelXp = 100; // Base XP required for level 2
  Function(int)? onLevelUp;
  OverlayEntry? _levelUpOverlay;
  BuildContext? _context;

  UserProvider() {
    // Initialize with mock user data
    _user = User(
      id: 'mock-user-id',
      email: 'user@example.com',
      displayName: 'Demo User',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      level: _level,
      currentXp: _currentXp,
      achievements: [],
    );
    _initializeRank();
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  void _initializeRank() {
    if (_user != null) {
      final rank = UserRank.getRankForLevel(_level);
      _user = _user!.copyWith(rank: rank.name);
    }
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  int get level => _level;
  int get currentXp => _currentXp;
  int get nextLevelXp => _nextLevelXp;
  
  UserRank get currentRank => UserRank.getRankForLevel(_level);
  UserRank? get nextRank => UserRank.getNextRank(_level);
  int get xpToNextRank {
    final nextRank = UserRank.getNextRank(_level);
    if (nextRank == null) return 0;
    return nextRank.requiredLevel - _level;
  }

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
        level: _level,
        currentXp: _currentXp,
        achievements: [],
      );
      _initializeRank();
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

  Future<void> _showLevelUpOverlay(int newLevel) async {
    if (_context == null) return;
    final context = _context!;
    if (!context.mounted) return;
    
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    _levelUpOverlay = OverlayEntry(
      builder: (context) => LevelUpOverlay(
        newLevel: newLevel,
        onDismiss: () {
          if (_levelUpOverlay != null) {
            _levelUpOverlay!.remove();
            _levelUpOverlay = null;
          }
        },
      ),
    );

    overlay.insert(_levelUpOverlay!);
    
    // Auto-remove after 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    if (context.mounted && overlay.mounted && _levelUpOverlay != null) {
      _levelUpOverlay!.remove();
      _levelUpOverlay = null;
    }
  }

  Future<void> addXp(int amount) async {
    debugPrint('UserProvider.addXp called with amount: $amount');
    debugPrint('Current XP before update: $_currentXp');
    
    // Add the XP amount
    _currentXp += amount;
    debugPrint('New XP after adding: $_currentXp');
    
    // Check for level up
    while (_currentXp >= _nextLevelXp) {
      _currentXp -= _nextLevelXp;
      _level++;
      // Increase XP required for next level (using a simple scaling formula)
      _nextLevelXp = (100 * (1.5 * (_level - 1))).round();
      debugPrint('Leveled up! New level: $_level, XP reset to: $_currentXp, Next level at: $_nextLevelXp');
      
      // Show level up overlay
      await _showLevelUpOverlay(_level);
    }
    
    // Update the user model if it exists
    if (_user != null) {
      final newRank = UserRank.getRankForLevel(_level);
      _user = _user!.copyWith(
        level: _level,
        currentXp: _currentXp,
        rank: newRank.name,
      );
    }
    
    debugPrint('Notifying listeners of XP update');
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

  @override
  void dispose() {
    if (_levelUpOverlay != null) {
      _levelUpOverlay!.remove();
      _levelUpOverlay = null;
    }
    super.dispose();
  }
} 