/// Refactored UserProvider focused purely on persistence
/// Effect evaluation is now handled by TalentPerkController

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart' as app_user;
import '../models/user_talent.dart';
import '../models/enhanced_user_perk.dart';
import '../models/state_delta.dart';
import '../models/theme_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/talent_management_service.dart';
import '../controllers/talent_perk_controller.dart';

/// Persistence-focused user provider
/// Effect evaluation is delegated to TalentPerkController
class UserProvider with ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final TalentPerkController _talentPerkController;

  app_user.User? _user;
  bool _isLoading = false;
  String? _error;

  // Callbacks for UI events (but not effect calculations)
  Function(int oldLevel, int newLevel)? onLevelUp;
  Function(TalentChoice talentChoice)? onTalentChoice;
  Function(EnhancedUserPerk perk)? onPerkUnlock;
  Function(ThemeType theme)? onThemeUnlock;

  // Getters
  app_user.User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TalentPerkController get talentPerkController => _talentPerkController;

  // Simple delegation to controller for effect-related queries
  bool hasPerk(String perk) => _user?.perks.contains(perk) ?? false;
  bool hasTalent(String talentId) => _user?.hasTalent(talentId) ?? false;
  bool hasProjectManagementTalent() =>
      _talentPerkController.hasProjectManagement();
  bool hasNLPTalent() => _talentPerkController.hasSmartCategorization();
  bool needsTalentChoice() => _talentPerkController.state.needsTalentChoice;

  // Basic user data getters (not effect-related)
  int get nextLevelXp {
    if (_user == null) return 100;
    return (_user!.level + 1) *
        100; // XP needed for NEXT level, not current level
  }

  TalentChoice? getAvailableTalentChoice() => _user?.getAvailableTalentChoice();

  UserProvider(
    this._authService,
    this._firestoreService,
    this._talentPerkController,
  ) {
    _authService.user.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    _setLoading(true);
    _clearError();

    try {
      if (firebaseUser == null) {
        _user = null;
        _talentPerkController.clear();
      } else {
        var userFromFirestore =
            await _firestoreService.getUser(firebaseUser.uid);
        if (userFromFirestore == null) {
          await _firestoreService.createUserFromFirebase(
            firebaseUser.uid,
            firebaseUser.displayName,
            firebaseUser.email,
          );
          userFromFirestore = await _firestoreService.getUser(firebaseUser.uid);
        }
        _user = userFromFirestore;

        // Update controller with new user data
        if (_user != null) {
          await _talentPerkController.updateUser(_user!);
        }
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }

    notifyListeners();
  }

  /// Apply state delta to user (pure persistence)
  Future<bool> applyStateDelta(StateDelta delta) async {
    if (_user == null || delta.user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final userDelta = delta.user!;
      app_user.User updatedUser = _user!;

      // Apply XP changes
      if (userDelta.xpChange != null) {
        final newCurrentXp = updatedUser.currentXp + userDelta.xpChange!;
        updatedUser = updatedUser.copyWith(currentXp: newCurrentXp);
      }

      // Apply level changes
      if (userDelta.levelChange != null) {
        final newLevel = updatedUser.level + userDelta.levelChange!;
        updatedUser = updatedUser.copyWith(level: newLevel);
      }

      // Apply new perks
      if (userDelta.newPerks != null) {
        final newPerks = [...updatedUser.perks, ...userDelta.newPerks!];
        updatedUser = updatedUser.copyWith(perks: newPerks);
      }

      // Apply new talents
      if (userDelta.newTalents != null) {
        final newTalents = [...updatedUser.talents, ...userDelta.newTalents!];
        updatedUser = updatedUser.copyWith(talents: newTalents);
      }

      // Apply additional changes
      if (userDelta.additionalChanges != null) {
        for (final entry in userDelta.additionalChanges!.entries) {
          switch (entry.key) {
            case 'streak':
              // Note: User model doesn't have currentStreak property
              // This would be handled by a separate streak tracking system
              break;
            case 'currentXp':
              // Override current XP (used for level overflow adjustments)
              final newCurrentXp = entry.value;
              if (newCurrentXp is int) {
                updatedUser = updatedUser.copyWith(currentXp: newCurrentXp);
              }
              break;
            case 'talentChoices':
              // Merge incoming map into the strongly-typed Map<int, String>
              final incoming = entry.value;
              if (incoming is Map) {
                final merged = Map<int, String>.from(updatedUser.talentChoices);
                incoming.forEach((k, v) {
                  final key = k is int ? k : int.tryParse(k.toString());
                  final value = v?.toString();
                  if (key != null && value != null) {
                    merged[key] = value;
                  }
                });
                updatedUser = updatedUser.copyWith(talentChoices: merged);
              }
              break;
            // Add other fields as needed
          }
        }
      }

      // Persist to Firestore
      await _firestoreService.setUser(updatedUser);

      // Update local state
      final oldUser = _user!;
      _user = updatedUser;

      // Update controller
      await _talentPerkController.updateUser(updatedUser);

      // Trigger callbacks for UI events (but don't calculate effects here)
      if (userDelta.levelChange != null && userDelta.levelChange! > 0) {
        onLevelUp?.call(oldUser.level, updatedUser.level);
      }

      // Trigger talent choice if needed
      if (updatedUser.needsTalentChoice()) {
        final talentChoice = updatedUser.getAvailableTalentChoice();
        if (talentChoice != null) {
          onTalentChoice?.call(talentChoice);
        }
      }

      // Trigger perk unlock notifications
      if (userDelta.newPerks != null) {
        for (final perkId in userDelta.newPerks!) {
          final perk = EnhancedUserPerks.getPerkById(perkId);
          if (perk != null) {
            onPerkUnlock?.call(perk);
          }
        }
      }

      // Trigger theme unlock for even levels
      if (userDelta.levelChange != null && userDelta.levelChange! > 0) {
        final newTheme = _getThemeUnlockedAtLevel(updatedUser.level);
        if (newTheme != null) {
          onThemeUnlock?.call(newTheme);
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Legacy XP addition method - now creates a StateDelta and applies it
  Future<void> addXp(int amount) async {
    if (_user == null) return;

    final oldLevel = _user!.level;
    final oldXp = _user!.currentXp;

    // Calculate new level using the existing logic
    int newXp = oldXp + amount;
    int newLevel = oldLevel;

    int requiredXp = _xpForLevel(newLevel + 1); // XP required for NEXT level
    while (newXp >= requiredXp) {
      newXp -= requiredXp;
      newLevel++;
      requiredXp = _xpForLevel(newLevel + 1); // XP required for NEXT level
    }

    final leveledUp = newLevel > oldLevel;
    final newPerks = leveledUp
        ? _getPerksUnlockedBetweenLevels(oldLevel, newLevel)
        : <String>[];

    // Create state delta
    final delta = StateDelta(
      user: UserStateDelta(
        xpChange: amount,
        levelChange: leveledUp ? (newLevel - oldLevel) : null,
        newPerks: newPerks.isNotEmpty ? newPerks : null,
        additionalChanges: {
          'currentXp': newXp, // Set the correct XP after level overflow
        },
      ),
      timestamp: DateTime.now(),
      operation: 'add_xp',
    );

    await applyStateDelta(delta);
  }

  /// Talent selection - pure persistence
  Future<TalentSelectionResult> selectTalent(String talentId, int level) async {
    if (_user == null) {
      return TalentSelectionResult.error('No user logged in');
    }

    final result =
        TalentManagementService.selectTalent(_user!, talentId, level);
    if (result.success && result.updatedUser != null) {
      await _firestoreService.setUser(result.updatedUser!);
      _user = result.updatedUser;

      // Update controller
      await _talentPerkController.updateUser(_user!);

      notifyListeners();
    }

    return result;
  }

  /// Force talent choice dialog
  Future<void> forceTalentChoice(TalentChoice talentChoice) async {
    onTalentChoice?.call(talentChoice);
  }

  /// Check for pending talent choices
  Future<void> checkPendingTalentChoices() async {
    if (_user == null) return;

    final pendingLevels = _user!.getPendingTalentLevels();
    for (final _ in pendingLevels) {
      final talentChoice = TalentManagementService.getNextTalentChoice(_user!);
      if (talentChoice != null) {
        onTalentChoice?.call(talentChoice);
        break; // Only show one at a time
      }
    }
  }

  /// Reset user to level one - pure persistence
  Future<void> resetToLevelOne() async {
    if (_user == null) return;

    final resetUser = _user!.copyWith(
      level: 1,
      currentXp: 0,
      perks: [],
      talents: [],
      talentChoices: {},
    );

    // Direct Firestore update for reset
    await _firestoreService.setUser(resetUser);
    _user = resetUser;

    // Update controller
    await _talentPerkController.updateUser(resetUser);

    notifyListeners();
  }

  /// Update profile picture - pure persistence
  Future<void> updateProfilePicture(String url) async {
    if (_user == null) return;

    _setLoading(true);
    try {
      await _firestoreService.updateUserProfilePicture(_user!.id, url);
      final updatedUser = _user!.copyWith(profilePictureUrl: url);
      _user = updatedUser;

      // Update controller
      await _talentPerkController.updateUser(updatedUser);

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh user data from Firestore
  Future<void> refresh() async {
    if (_user?.id == null) return;

    _setLoading(true);
    _clearError();

    try {
      final refreshedUser = await _firestoreService.getUser(_user!.id);
      if (refreshedUser != null) {
        _user = refreshedUser;
        await _talentPerkController.updateUser(refreshedUser);
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Private helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // XP calculation helper (kept for legacy compatibility)
  int _xpForLevel(int level) {
    return level * 100;
  }

  // Perk unlock helper (kept for legacy compatibility)
  List<String> _getPerksUnlockedBetweenLevels(int oldLevel, int newLevel) {
    final perks = <String>[];

    for (int level = oldLevel + 1; level <= newLevel; level++) {
      switch (level) {
        case 1:
          perks.add('routine_master');
          break;
        case 3:
          perks.add('task_starter');
          break;
        case 5:
          perks.add('health_expert');
          break;
        case 7:
          perks.add('morning_motivation');
          break;
        case 8:
          perks.add('lucky_charm');
          break;
        case 9:
          perks.add('difficulty_dabbler');
          break;
        case 11:
          perks.add('category_explorer');
          break;
        case 12:
          perks.add('streak_guardian');
          break;
        case 13:
          perks.add('consistency_champion');
          break;
        case 15:
          perks.add('learning_master');
          break;
        case 18:
          perks.add('xp_veteran');
          break;
        case 22:
          perks.add('work_efficiency');
          break;
        case 25:
          perks.add('grand_master');
          break;
        default:
          // No perks for other levels
          break;
      }
    }

    return perks;
  }

  // Theme unlock helper for even levels
  ThemeType? _getThemeUnlockedAtLevel(int level) {
    switch (level) {
      case 2:
        return ThemeType.crimsonWave;
      case 4:
        return ThemeType.amberBlaze;
      case 6:
        return ThemeType.emeraldMist;
      case 8:
        return ThemeType.violetStorm;
      default:
        return null;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Backwards compatibility methods
extension UserProviderLegacySupport on UserProvider {
  /// Get active perks - delegated to controller
  List<EnhancedUserPerk> getActivePerks() {
    return talentPerkController.state.unlockedPerks;
  }

  /// Get perks for category - delegated to controller
  List<EnhancedUserPerk> getPerksForCategory(String category) {
    return talentPerkController.state.unlockedPerks
        .where((perk) => perk.effects.any((effect) =>
            effect.effect == PerkEffect.categoryBonus &&
            effect.category?.toLowerCase() == category.toLowerCase()))
        .toList();
  }

  /// Get perk summary - delegated to controller
  Map<String, dynamic> getPerkSummary() {
    return talentPerkController.getPerkSummary();
  }
}

/// Extension for effect-related queries (all delegated to controller)
extension UserProviderEffectQueries on UserProvider {
  /// Get XP preview for task - delegated to controller
  Future<int> getXPPreview({
    required int baseXP,
    required String category,
    required String difficulty,
  }) {
    return talentPerkController.calculateXPPreview(
      baseXP: baseXP,
      category: category,
      difficulty: difficulty,
    );
  }

  /// Get effect preview for category - delegated to controller
  Future<List<String>> getEffectPreview(String category) {
    return talentPerkController.getEffectPreviewForContext(category: category);
  }

  /// Check if has effects for category - delegated to controller
  bool hasEffectsForCategory(String category) {
    return talentPerkController.hasEffectsForCategory(category);
  }
}
