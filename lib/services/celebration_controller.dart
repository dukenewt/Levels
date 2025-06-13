import 'package:flutter/material.dart';
import '../models/celebration_data.dart';
import '../widgets/level_up_celebration.dart';

/// Controls how celebrations are presented to the user
/// This separates the presentation logic from the visual appearance
class CelebrationController {
  static final CelebrationController _instance = CelebrationController._();
  static CelebrationController get instance => _instance;
  CelebrationController._();

  // Keep track of active overlays
  OverlayEntry? _currentOverlay;
  bool _isShowingCelebration = false;

  /// Show a level up celebration using the provided data
  /// This method handles the presentation logic (when, how long, etc.)
  /// while delegating the appearance to the widget
  Future<void> showLevelUpCelebration({
    required BuildContext context,
    required CelebrationData data,
  }) async {
    // Don't show multiple celebrations at once
    if (_isShowingCelebration) {
      _dismissCurrentCelebration();
    }

    _isShowingCelebration = true;
    
    // Create the overlay entry with the celebration widget
    _currentOverlay = OverlayEntry(
      builder: (context) => LevelUpCelebration(
        celebrationData: data,
        onDismiss: _dismissCurrentCelebration,
      ),
    );

    // Insert into the overlay
    final overlay = Overlay.of(context);
    overlay.insert(_currentOverlay!);

    // Log the celebration for debugging/analytics
    debugPrint('🎉 Showing level up celebration: ${data.toString()}');
  }

  /// Show different types of celebrations based on the data
  /// This allows for future customization of celebration types
  Future<void> showCelebration({
    required BuildContext context,
    required CelebrationData data,
  }) async {
    // For now, we only have level up celebrations
    // But this method could be expanded to handle different types
    await showLevelUpCelebration(context: context, data: data);
  }

  /// Dismiss the current celebration
  void _dismissCurrentCelebration() {
    if (_currentOverlay != null) {
      _currentOverlay!.remove();
      _currentOverlay = null;
    }
    _isShowingCelebration = false;
  }

  /// Force dismiss any active celebration
  /// Useful for when the user navigates away or the app needs to clean up
  void forceHide() {
    _dismissCurrentCelebration();
  }

  /// Check if a celebration is currently being shown
  bool get isShowingCelebration => _isShowingCelebration;
} 