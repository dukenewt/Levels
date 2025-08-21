import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart' as app_user;
import '../models/user_talent.dart';
import '../models/enhanced_user_perk.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/talent_management_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  app_user.User? _user;
  Function(int oldLevel, int newLevel)? onLevelUp;
  Function(TalentChoice talentChoice)? onTalentChoice;
  Function(EnhancedUserPerk perk)? onPerkUnlock;
  
  app_user.User? get user => _user;

  int get nextLevelXp {
    if (_user == null) return 100;
    return _user!.level * 100;
  }

  bool hasPerk(String perk) {
    return _user?.perks.contains(perk) ?? false;
  }

  // Talent system getters
  bool hasTalent(String talentId) => _user?.hasTalent(talentId) ?? false;
  bool hasProjectManagementTalent() => _user?.hasProjectManagementTalent() ?? false;
  bool hasNLPTalent() => _user?.hasNLPTalent() ?? false;
  bool needsTalentChoice() => _user?.needsTalentChoice() ?? false;
  
  List<EnhancedUserPerk> getActivePerks() {
    if (_user == null) return [];
    return EnhancedUserPerks.getAvailablePerksForLevel(_user!.level);
  }
  
  TalentChoice? getAvailableTalentChoice() => _user?.getAvailableTalentChoice();

  void updateDependencies(AuthService authService, FirestoreService firestoreService) {
    // This is a bit of a hack to make this work with the proxy provider
    // but since the services are singletons it's fine.
  }

  UserProvider(this._authService, this._firestoreService) {
    _authService.user.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
    } else {
      var userFromFirestore = await _firestoreService.getUser(firebaseUser.uid);
      if (userFromFirestore == null) {
        await _firestoreService.createUserFromFirebase(
          firebaseUser.uid,
          firebaseUser.displayName,
          firebaseUser.email,
        );
        userFromFirestore = await _firestoreService.getUser(firebaseUser.uid);
      }
      _user = userFromFirestore;
    }
    notifyListeners();
  }

  Future<void> addXp(int amount) async {
    if (_user != null) {
      int oldLevel = _user!.level;
      int newXp = _user!.currentXp + amount;
      int newLevel = _user!.level;
      bool leveledUp = false;

      // Recompute required XP per level as we advance levels
      int requiredXp = _xpForLevel(newLevel);
      while (newXp >= requiredXp) {
        newXp -= requiredXp;
        newLevel++;
        leveledUp = true;
        requiredXp = _xpForLevel(newLevel);
      }
      
      List<String> newPerks = _getPerksUnlockedBetweenLevels(oldLevel, newLevel);
      
      final updatedUser = _user!.copyWith(
        currentXp: newXp,
        level: newLevel,
        perks: _user!.perks + newPerks,
      );
      await _firestoreService.setUser(updatedUser);
      _user = updatedUser;
      
      if (leveledUp && onLevelUp != null) {
        onLevelUp!(oldLevel, newLevel);
      }
      
      // Check for talent choices after level up
      if (leveledUp && updatedUser.needsTalentChoice() && onTalentChoice != null) {
        final talentChoice = updatedUser.getAvailableTalentChoice();
        if (talentChoice != null) {
          // Defer UI to caller; callback will handle safe timing
          onTalentChoice!(talentChoice);
        }
      }
      
      // Check for new perk unlocks
      for (final perk in EnhancedUserPerks.getAvailablePerksForLevel(newLevel)) {
        if (perk.requiredLevel > oldLevel && perk.requiredLevel <= newLevel && onPerkUnlock != null) {
          onPerkUnlock!(perk);
        }
      }
      
            notifyListeners();
    }
  }

  // XP required to advance from `level` to `level + 1`
  int _xpForLevel(int level) {
    // Current formula: linear scale (kept consistent with nextLevelXp usage)
    // Adjust here if progression curve changes in the future.
    return level * 100;
  }

  Future<void> resetToLevelOne() async {
    if (_user != null) {
      final updatedUser = _user!.copyWith(
        level: 1,
        currentXp: 0,
      );
      await _firestoreService.setUser(updatedUser);
      _user = updatedUser;
      notifyListeners();
    }
  }

  List<String> _getPerksUnlockedBetweenLevels(int oldLevel, int newLevel) {
    // Define perks unlocked at specific levels
    final perks = <String>[];
    
    for (int level = oldLevel + 1; level <= newLevel; level++) {
        switch (level) {
          case 5:
            // Previously unlocked 'smart_suggestions' — removed
            break;
        case 10:
          perks.add('custom_categories');
          break;
        case 15:
          perks.add('advanced_stats');
          break;
        case 20:
          perks.add('theme_customization');
          break;
        case 25:
          perks.add('export_data');
          break;
        case 30:
          perks.add('priority_scheduling');
          break;
        default:
          if (level % 10 == 0) {
            perks.add('bonus_xp_multiplier');
          }
      }
    }
    
    return perks;
  }

  Future<void> updateProfilePicture(String url) async {
    if (_user != null) {
      await _firestoreService.updateUserProfilePicture(_user!.id, url);
      final updatedUser = _user!.copyWith(profilePictureUrl: url);
      _user = updatedUser;
      notifyListeners();
    }
  }

  // Talent Management Methods
  Future<TalentSelectionResult> selectTalent(String talentId, int level) async {
    if (_user == null) {
      return TalentSelectionResult.error('No user logged in');
    }

    final result = TalentManagementService.selectTalent(_user!, talentId, level);
    if (result.success && result.updatedUser != null) {
      await _firestoreService.setUser(result.updatedUser!);
      _user = result.updatedUser;
      notifyListeners();
    }

    return result;
  }

  Future<void> forceTalentChoice(TalentChoice talentChoice) async {
    // This method can be called to trigger the talent choice UI
    if (onTalentChoice != null) {
      onTalentChoice!(talentChoice);
    }
  }

  // Check and handle pending talent choices on app start
  Future<void> checkPendingTalentChoices() async {
    if (_user == null) return;

    final pendingLevels = _user!.getPendingTalentLevels();
    for (final _ in pendingLevels) {
      final talentChoice = TalentManagementService.getNextTalentChoice(_user!);
      if (talentChoice != null && onTalentChoice != null) {
        onTalentChoice!(talentChoice);
        break; // Only show one at a time
      }
    }
  }

  // Enhanced perk system methods
  List<EnhancedUserPerk> getPerksForCategory(String category) {
    if (_user == null) return [];
    return EnhancedUserPerks.getAvailablePerksForLevel(_user!.level)
        .where((perk) => perk.effects.any((effect) => 
            effect.effect == PerkEffect.categoryBonus && 
            effect.category?.toLowerCase() == category.toLowerCase()))
        .toList();
  }

  Map<String, dynamic> getPerkSummary() {
    if (_user == null) return {};
    
    final activePerks = getActivePerks();
    Map<String, List<String>> effectsByCategory = {};
    List<String> generalEffects = [];
    List<String> specialEffects = [];

    for (final perk in activePerks) {
      for (final effect in perk.effects) {
        String description = '';
        
        switch (effect.effect) {
          case PerkEffect.categoryBonus:
            description = '+${(effect.value * 100).toInt()}% XP';
            final category = effect.category ?? 'General';
            effectsByCategory[category] = effectsByCategory[category] ?? [];
            effectsByCategory[category]!.add(description);
            break;
            
          case PerkEffect.xpBonus:
            description = '+${(effect.value * 100).toInt()}% All XP';
            generalEffects.add(description);
            break;
            
          case PerkEffect.lootBoxBonus:
            description = '+${(effect.value * 100).toInt()}% Loot Box Chance';
            generalEffects.add(description);
            break;
            
          case PerkEffect.streakFreeze:
            description = 'Streak Protection';
            specialEffects.add(description);
            break;
        }
      }
    }

    return {
      'categoryEffects': effectsByCategory,
      'generalEffects': generalEffects,
      'specialEffects': specialEffects,
      'totalPerks': activePerks.length,
    };
  }
} 
