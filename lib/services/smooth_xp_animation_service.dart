import 'package:flutter/material.dart';
import '../providers/user_provider.dart';
import '../services/enhanced_game_experience_manager.dart';

/// Service to handle smooth XP animations
/// This ensures that XP gains animate smoothly in the ring progress
class SmoothXPAnimationService {
  static final SmoothXPAnimationService _instance = SmoothXPAnimationService._();
  static SmoothXPAnimationService get instance => _instance;
  SmoothXPAnimationService._();

  bool _isAnimating = false;
  
  /// Add XP with smooth animation
  /// This is the preferred method for adding XP that should animate smoothly
  Future<void> addXPWithAnimation({
    required UserProvider userProvider,
    required int xpAmount,
    Duration? animationDelay,
  }) async {
    if (_isAnimating) {
      debugPrint('💫 XP animation already in progress, queuing...');
      // Wait for current animation to finish
      await Future.delayed(const Duration(milliseconds: 100));
      return addXPWithAnimation(
        userProvider: userProvider,
        xpAmount: xpAmount,
        animationDelay: animationDelay,
      );
    }

    _isAnimating = true;
    
    try {
      debugPrint('💫 Starting smooth XP animation: +$xpAmount XP');
      
      // Track XP progress BEFORE adding XP
      // EnhancedGameExperienceManager.instance.trackXPProgress(userProvider);
      
      // Add the XP (this will trigger the ring animation)
      await userProvider.addXp(xpAmount);
      
      debugPrint('💫 XP added successfully, animation should be visible');
      
      // Optional delay for visual effect
      if (animationDelay != null) {
        await Future.delayed(animationDelay);
      }
      
    } catch (e) {
      debugPrint('💫 Error during XP animation: $e');
    } finally {
      _isAnimating = false;
    }
  }

  /// Add multiple XP amounts with staggered animations
  /// Useful for when multiple tasks are completed at once
  Future<void> addMultipleXPWithStaggeredAnimation({
    required UserProvider userProvider,
    required List<int> xpAmounts,
    Duration staggerDelay = const Duration(milliseconds: 300),
  }) async {
    for (int i = 0; i < xpAmounts.length; i++) {
      await addXPWithAnimation(
        userProvider: userProvider,
        xpAmount: xpAmounts[i],
      );
      
      // Add stagger delay between animations (except for the last one)
      if (i < xpAmounts.length - 1) {
        await Future.delayed(staggerDelay);
      }
    }
  }

  /// Quick method to test XP animation (for debugging)
  Future<void> testXPAnimation(UserProvider userProvider, {int amount = 25}) async {
    debugPrint('🧪 Testing XP animation with $amount XP');
    await addXPWithAnimation(
      userProvider: userProvider,
      xpAmount: amount,
    );
  }

  bool get isAnimating => _isAnimating;
} 