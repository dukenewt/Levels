import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/secure_user_provider.dart';
import '../models/user_rank.dart';
import '../models/user_perk.dart';
import '../models/celebration_data.dart';
import '../services/celebration_controller.dart';

/// Manages all game-like experiences in the app
/// This centralizes the logic for celebrations, animations, and rewards
/// but delegates the presentation to specialized controllers
class GameExperienceManager {
  static final GameExperienceManager _instance = GameExperienceManager._();
  static GameExperienceManager get instance => _instance;
  GameExperienceManager._();
  
  // Keep track of what's happening
  bool _isProcessingLevelUp = false;
  BuildContext? _currentContext;
  
  /// Initialize the manager with a context
  /// Call this from your main app or dashboard screen
  void initialize(BuildContext context) {
    _currentContext = context;
    
    // Set up the level up callback in the user provider
    final userProvider = Provider.of<SecureUserProvider>(context, listen: false);
    userProvider.setLevelUpCallback(_handleLevelUp);
    
    debugPrint('🎮 GameExperienceManager: Successfully initialized with callback');
  }
  
  /// Handle level up events with proper sequencing
  /// This creates the celebration data and delegates presentation to the controller
  void _handleLevelUp(int oldLevel, int newLevel) {
    debugPrint('🎮 GameExperienceManager: Level up triggered! $oldLevel -> $newLevel');
    
    if (_isProcessingLevelUp || _currentContext == null) {
      debugPrint('🎮 GameExperienceManager: Skipping - already processing: $_isProcessingLevelUp or no context: ${_currentContext == null}');
      return;
    }
    
    _isProcessingLevelUp = true;
    
    // Get the current context and user data
    final context = _currentContext!;
    final userProvider = Provider.of<SecureUserProvider>(context, listen: false);
    final currentRank = userProvider.currentRank;
    
    // Check what perks were unlocked between old and new level
    final unlockedPerks = _getPerksUnlockedBetweenLevels(oldLevel, newLevel);
    
    debugPrint('🎮 GameExperienceManager: Creating celebration data for rank: ${currentRank.name}, perks: $unlockedPerks');
    
    // Create the celebration data
    final celebrationData = CelebrationData(
      oldLevel: oldLevel,
      newLevel: newLevel,
      rankName: currentRank.name,
      rankColor: currentRank.color,
      unlockedPerks: unlockedPerks,
      newRank: currentRank,
    );
    
    // Small delay to ensure all UI updates have propagated
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_currentContext != null) {
        // Delegate the presentation to the celebration controller
        CelebrationController.instance.showCelebration(
          context: context,
          data: celebrationData,
        );
        
        // Reset the processing flag after the celebration
        Future.delayed(const Duration(seconds: 5), () {
          _isProcessingLevelUp = false;
        });
      }
    });
  }
  
  /// Get list of perks unlocked between two levels
  List<String> _getPerksUnlockedBetweenLevels(int oldLevel, int newLevel) {
    final unlockedPerks = <String>[];
    
    // Check each perk to see if it was unlocked in this level range
    for (final perk in UserPerks.allPerks) {
      if (perk.requiredLevel > oldLevel && perk.requiredLevel <= newLevel) {
        unlockedPerks.add(perk.name);
      }
    }
    
    return unlockedPerks;
  }
  
  /// Clean up when the app is disposed
  void dispose() {
    _currentContext = null;
    // Also clean up any active celebrations
    CelebrationController.instance.forceHide();
  }
  
  /// Test method to trigger a celebration manually (for debugging)
  void triggerTestCelebration() {
    if (_currentContext != null) {
      debugPrint('🎮 GameExperienceManager: Triggering test celebration');
      _handleLevelUp(8, 9);
    } else {
      debugPrint('🎮 GameExperienceManager: Cannot trigger test - no context');
    }
  }
} 