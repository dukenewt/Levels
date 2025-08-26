import 'package:flutter/material.dart';
import '../models/celebration_data.dart';
import '../widgets/ring_unraveling_celebration.dart';

/// Enhanced celebration controller that uses the ring unraveling animation
class EnhancedCelebrationController {
  static final EnhancedCelebrationController _instance =
      EnhancedCelebrationController._();
  static EnhancedCelebrationController get instance => _instance;
  EnhancedCelebrationController._();

  OverlayEntry? _currentOverlay;
  bool _isShowingCelebration = false;

  /// Show the new ring unraveling celebration with enhanced XP bar styling
  Future<void> showLevelUpCelebration({
    required BuildContext context,
    required CelebrationData data,
    double? preCompletionProgress, // Progress before level up
    Color? xpBarColor, // Optional XP bar color override
  }) async {
    if (_isShowingCelebration) {
      _dismissCurrentCelebration();
    }

    _isShowingCelebration = true;

    // For level up celebrations, we want to show the ring that just completed
    // If no specific progress provided, assume the ring was full (1.0)
    final ringProgress = preCompletionProgress ?? 1.0;

    // Use provided XP bar color or fall back to rank color
    final celebrationColor = xpBarColor ?? data.rankColor;

    // Create the overlay with your enhanced ring animation
    _currentOverlay = OverlayEntry(
      builder: (context) => RingUnravelingCelebration(
        initialProgress: ringProgress,
        oldLevel: data.oldLevel,
        newLevel: data.newLevel,
        ringColor: celebrationColor,
        unlockedPerks: data.unlockedPerks,
        onComplete: _dismissCurrentCelebration,
      ),
    );

    final overlay = Overlay.of(context);
    overlay.insert(_currentOverlay!);

    debugPrint(
        '🎉 Enhanced ring unraveling celebration started for level ${data.newLevel}');
    debugPrint('   Progress: ${(ringProgress * 100).toStringAsFixed(1)}%');
    debugPrint('   Color: ${celebrationColor.toString()}');
    debugPrint('   Unlocked perks: ${data.unlockedPerks.join(", ")}');
  }

  /// Show celebration for partial progress (like when a big task is completed)
  /// Enhanced with XP bar color matching
  Future<void> showXPGainCelebration({
    required BuildContext context,
    required double currentProgress,
    required Color ringColor,
    required int xpGained,
    Duration? duration,
  }) async {
    if (_isShowingCelebration) return;

    _isShowingCelebration = true;

    try {
      // For XP gain celebrations, we could show a mini version
      // This could be a separate, simpler animation
      debugPrint('💫 XP gain celebration: +$xpGained XP');
      debugPrint(
          '   Current progress: ${(currentProgress * 100).toStringAsFixed(1)}%');
      debugPrint('   Ring color: ${ringColor.toString()}');

      // You could implement a simpler ring animation here for non-level-up XP gains
      // For now, we'll show a brief pulse effect or mini celebration

      // For now, just dismiss after the specified duration
      final celebrationDuration =
          duration ?? const Duration(milliseconds: 1500);
      await Future.delayed(celebrationDuration);
    } catch (e) {
      debugPrint('Error in XP gain celebration: $e');
    } finally {
      _isShowingCelebration = false;
    }
  }

  /// Show a preview of the unraveling animation for testing
  Future<void> showPreviewCelebration({
    required BuildContext context,
    required Color xpBarColor,
    int level = 15,
    double progress = 1.0,
    List<String>? testPerks,
  }) async {
    if (_isShowingCelebration) {
      _dismissCurrentCelebration();
    }

    _isShowingCelebration = true;

    final perks =
        testPerks ?? ['Enhanced Focus', 'Streak Master', 'Time Warrior'];

    _currentOverlay = OverlayEntry(
      builder: (context) => RingUnravelingCelebration(
        initialProgress: progress,
        oldLevel: level - 1,
        newLevel: level,
        ringColor: xpBarColor,
        unlockedPerks: perks,
        onComplete: _dismissCurrentCelebration,
      ),
    );

    final overlay = Overlay.of(context);
    overlay.insert(_currentOverlay!);

    debugPrint('🎭 Preview celebration started (Level $level)');
    debugPrint('   XP bar color: ${xpBarColor.toString()}');
    debugPrint('   Test perks: ${perks.join(", ")}');
  }

  void _dismissCurrentCelebration() {
    if (_currentOverlay != null) {
      _currentOverlay!.remove();
      _currentOverlay = null;
    }
    _isShowingCelebration = false;
    debugPrint('🎉 Enhanced ring celebration dismissed');
  }

  void forceHide() {
    _dismissCurrentCelebration();
  }

  bool get isShowingCelebration => _isShowingCelebration;

  /// Get the primary theme color for XP bars from the current theme
  Color getXPBarColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.colorScheme.primary;
  }

  /// Get a gradient color that matches the XP bar styling
  List<Color> getXPBarGradientColors(Color baseColor) {
    return [
      baseColor.withOpacity(0.6),
      baseColor,
      baseColor.withOpacity(0.8),
    ];
  }
}
