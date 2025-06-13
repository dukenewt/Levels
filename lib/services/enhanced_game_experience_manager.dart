import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/secure_user_provider.dart';
import '../models/celebration_data.dart';
import 'enhanced_celebration_controller.dart';

class EnhancedGameExperienceManager {
  static final EnhancedGameExperienceManager _instance = EnhancedGameExperienceManager._();
  static EnhancedGameExperienceManager get instance => _instance;
  EnhancedGameExperienceManager._();
  
  bool _isProcessingLevelUp = false;
  BuildContext? _currentContext;
  
  // Track XP state for ring animation
  double _lastXPProgress = 0.0;
  int _lastLevel = 1;
  
  void initialize(BuildContext context) {
    _currentContext = context;
    
    final userProvider = Provider.of<SecureUserProvider>(context, listen: false);
    
    // Initialize tracking values
    _lastLevel = userProvider.level;
    _updateXPProgress(userProvider);
    
    // Set up level up callback
    userProvider.setLevelUpCallback(_handleLevelUp);
    
    debugPrint('🎮 Enhanced GameExperienceManager: Successfully initialized at level $_lastLevel');
  }
  
  /// Call this whenever XP changes but before level up processing
  void trackXPProgress(SecureUserProvider userProvider) {
    if (userProvider.level == _lastLevel) {
      _updateXPProgress(userProvider);
    }
  }
  
  void _updateXPProgress(SecureUserProvider userProvider) {
    if (userProvider.nextLevelXp > 0) {
      _lastXPProgress = userProvider.currentXp / userProvider.nextLevelXp;
    }
  }
  
  void _handleLevelUp(int oldLevel, int newLevel) {
    debugPrint('🎮 Ring celebration triggered! $oldLevel -> $newLevel (last progress: $_lastXPProgress)');
    
    if (_isProcessingLevelUp || _currentContext == null) {
      return;
    }
    
    _isProcessingLevelUp = true;
    
    final context = _currentContext!;
    final userProvider = Provider.of<SecureUserProvider>(context, listen: false);
    final currentRank = userProvider.currentRank;
    
    // Use the XP progress from just before the level up
    // This should be close to 1.0 (the completed ring)
    final ringProgress = _lastXPProgress;
    
    final celebrationData = CelebrationData(
      oldLevel: oldLevel,
      newLevel: newLevel,
      rankName: currentRank.name,
      rankColor: currentRank.color,
      unlockedPerks: _getPerksUnlockedBetweenLevels(oldLevel, newLevel),
      newRank: currentRank,
    );
    
    // Update our tracking for the new level
    _lastLevel = newLevel;
    _updateXPProgress(userProvider);
    
    // Small delay to ensure UI updates have propagated
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_currentContext != null) {
        EnhancedCelebrationController.instance.showLevelUpCelebration(
          context: context,
          data: celebrationData,
          preCompletionProgress: ringProgress,
        );
        
        Future.delayed(const Duration(seconds: 5), () {
          _isProcessingLevelUp = false;
        });
      }
    });
  }
  
  /// Call this when XP is gained (for potential smaller celebrations)
  void handleXPGain(int xpGained) {
    if (_currentContext == null) return;
    
    final context = _currentContext!;
    final userProvider = Provider.of<SecureUserProvider>(context, listen: false);
    
    // Update progress tracking
    trackXPProgress(userProvider);
    
    // For significant XP gains, you might want to show a mini celebration
    if (xpGained >= 50) { // Threshold for celebration
      EnhancedCelebrationController.instance.showXPGainCelebration(
        context: context,
        currentProgress: _lastXPProgress,
        ringColor: userProvider.currentRank.color,
        xpGained: xpGained,
      );
    }
  }
  
  List<String> _getPerksUnlockedBetweenLevels(int oldLevel, int newLevel) {
    // Define perks unlocked at specific levels
    final perks = <String>[];
    
    for (int level = oldLevel + 1; level <= newLevel; level++) {
      switch (level) {
        case 5:
          perks.add('Smart Suggestions');
          break;
        case 10:
          perks.add('Custom Categories');
          break;
        case 15:
          perks.add('Advanced Stats');
          break;
        case 20:
          perks.add('Theme Customization');
          break;
        case 25:
          perks.add('Export Data');
          break;
        case 30:
          perks.add('Priority Scheduling');
          break;
        default:
          if (level % 10 == 0) {
            perks.add('Bonus XP Multiplier');
          }
      }
    }
    
    return perks;
  }
  
  void dispose() {
    _currentContext = null;
    EnhancedCelebrationController.instance.forceHide();
  }
} 