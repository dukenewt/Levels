import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart' as app_user;
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  app_user.User? _user;
  Function(int oldLevel, int newLevel)? onLevelUp;

  app_user.User? get user => _user;

  int get nextLevelXp {
    if (_user == null) return 100;
    return _user!.level * 100;
  }

  bool hasPerk(String perk) {
    return _user?.perks.contains(perk) ?? false;
  }

  void updateDependencies(
      AuthService authService, FirestoreService firestoreService) {
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

      while (newXp >= nextLevelXp) {
        newXp -= nextLevelXp;
        newLevel++;
        leveledUp = true;
      }

      List<String> newPerks =
          _getPerksUnlockedBetweenLevels(oldLevel, newLevel);

      final updatedUser = _user!.copyWith(
        currentXp: newXp,
        level: newLevel,
        perks: _user!.perks + newPerks,
      );
      await _firestoreService.setUser(updatedUser);
      _user = updatedUser;

      if (leveledUp && onLevelUp != null) {
        onLevelUp!(_user!.level, newLevel);
      }

      notifyListeners();
    }
  }

  List<String> _getPerksUnlockedBetweenLevels(int oldLevel, int newLevel) {
    // Define perks unlocked at specific levels
    final perks = <String>[];

    for (int level = oldLevel + 1; level <= newLevel; level++) {
      switch (level) {
        case 5:
          perks.add('smart_suggestions');
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
}
