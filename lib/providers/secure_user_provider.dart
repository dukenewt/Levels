import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/user_rank.dart';
import '../services/secure_storage_service.dart';
import '../core/error_handling.dart';

/// States for async operations to provide proper loading indicators
enum UserOperationState {
  idle,
  loading,
  saving,
  signingIn,
  signingUp,
  signingOut,
}

class SecureUserProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  int _level = 1;
  int _currentXp = 0;
  int _nextLevelXp = 100;
  Function(int)? onLevelUp;
  OverlayEntry? _levelUpOverlay;
  BuildContext? _context;

  bool _isInitialized = false;
  bool _isInitializing = false;
  UserOperationState _operationState = UserOperationState.idle;
  AppException? _lastError;
  final SecureStorageService _storage;

  SecureUserProvider({required SecureStorageService storage}) : _storage = storage {
    _initializeProvider();
  }

  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  UserOperationState get operationState => _operationState;
  AppException? get lastError => _lastError;
  bool get isLoading => _operationState == UserOperationState.loading;

  User? get user => _user;
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

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> _initializeProvider() async {
    if (_isInitializing || _isInitialized) return;
    _isInitializing = true;
    _operationState = UserOperationState.loading;
    notifyListeners();
    try {
      final result = await _storage.userRepository.getUserData();
      if (result.isSuccess) {
        final userData = result.data!;
        if (userData.isNotEmpty) {
          _user = User.fromJson(userData);
          _level = _user!.level;
          _currentXp = _user!.currentXp;
          _nextLevelXp = getNextLevelThreshold();
        } else {
          // Initialize with default user if no data
          _user = User(
            id: 'user-${DateTime.now().millisecondsSinceEpoch}',
            email: '',
            displayName: 'New User',
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
            level: _level,
            currentXp: _currentXp,
            achievements: [],
          );
        }
        _isInitialized = true;
        _lastError = null;
      } else {
        _lastError = result.error;
        _isInitialized = true; // Allow degraded mode
      }
    } catch (e, stackTrace) {
      _lastError = AppException('Failed to initialize user provider', originalError: e);
      ErrorHandlingService().logError(_lastError!, stackTrace: stackTrace);
      _isInitialized = true;
    } finally {
      _isInitializing = false;
      _operationState = UserOperationState.idle;
      notifyListeners();
    }
  }

  int getNextLevelThreshold() {
    if (_user == null) return 100;
    return _user!.level * 100;
  }

  Future<Result<void>> signIn(String email, String password) async {
    _operationState = UserOperationState.signingIn;
    notifyListeners();
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1000));
      // In a real app, validate credentials here
      // For now, just mark as signed in
      return Result.success(null);
    } catch (e, stackTrace) {
      final error = AppException('Failed to sign in', originalError: e);
      ErrorHandlingService().logError(error, stackTrace: stackTrace);
      _lastError = error;
      return Result.failure(error);
    } finally {
      _operationState = UserOperationState.idle;
      notifyListeners();
    }
  }

  Future<Result<void>> signUp(String email, String password, String displayName) async {
    _operationState = UserOperationState.signingUp;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      _user = User(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        level: _level,
        currentXp: _currentXp,
        achievements: [],
      );
      await _saveUser();
      return Result.success(null);
    } catch (e, stackTrace) {
      final error = AppException('Failed to sign up', originalError: e);
      ErrorHandlingService().logError(error, stackTrace: stackTrace);
      _lastError = error;
      return Result.failure(error);
    } finally {
      _operationState = UserOperationState.idle;
      notifyListeners();
    }
  }

  Future<Result<void>> signOut() async {
    _operationState = UserOperationState.signingOut;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _user = null;
      await _storage.userRepository.deleteUserData();
      return Result.success(null);
    } catch (e, stackTrace) {
      final error = AppException('Failed to sign out', originalError: e);
      ErrorHandlingService().logError(error, stackTrace: stackTrace);
      _lastError = error;
      return Result.failure(error);
    } finally {
      _operationState = UserOperationState.idle;
      notifyListeners();
    }
  }

  Future<void> addXp(int amount) async {
    debugPrint('SecureUserProvider.addXp called with amount: $amount');
    debugPrint('Current XP before update: $_currentXp');
    _currentXp += amount;
    debugPrint('New XP after adding: $_currentXp');
    while (_currentXp >= _nextLevelXp) {
      _currentXp -= _nextLevelXp;
      _level++;
      _nextLevelXp = (100 * (1.5 * (_level - 1))).round();
      debugPrint('Leveled up! New level: $_level, XP reset to: $_currentXp, Next level at: $_nextLevelXp');
      // Optionally show level up overlay
    }
    if (_user != null) {
      final newRank = UserRank.getRankForLevel(_level);
      _user = _user!.copyWith(
        level: _level,
        currentXp: _currentXp,
        rank: newRank.name,
      );
      await _saveUser();
    }
    notifyListeners();
  }

  Future<Result<void>> _saveUser() async {
    if (_user == null) {
      return Result.failure(ValidationException('No user to save'));
    }
    try {
      final saveResult = await _storage.userRepository.saveUserData(_user!.toJson());
      if (saveResult.isSuccess) {
        return Result.success(null);
      } else {
        _lastError = saveResult.error;
        return Result.failure(saveResult.error!);
      }
    } catch (e, stackTrace) {
      final error = AppException('Failed to save user', originalError: e);
      ErrorHandlingService().logError(error, stackTrace: stackTrace);
      _lastError = error;
      return Result.failure(error);
    }
  }

  void clearLastError() {
    _lastError = null;
    notifyListeners();
  }

  void showErrorToUser(BuildContext context, AppException error) {
    ErrorHandlingService().showError(context, error);
  }
} 