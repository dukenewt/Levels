/// Service to trigger talent selection using new architecture
/// This bridges the new TalentPerkController with existing UI

import 'package:flutter/material.dart';
import '../controllers/talent_perk_controller.dart';
import '../models/user_talent.dart';
import '../services/talent_dialog_service.dart';
import '../config/feature_flags.dart';

class TalentTriggerService with FeatureFlagMixin {
  static final TalentTriggerService _instance =
      TalentTriggerService._internal();
  static TalentTriggerService get instance => _instance;

  TalentTriggerService._internal();

  BuildContext? _context;
  TalentPerkController? _controller;
  bool _isMonitoring = false;
  int? _lastCheckedLevel;

  /// Initialize with context and controller
  void initialize(BuildContext context, TalentPerkController controller) {
    _context = context;
    _controller = controller;

    if (useNewTalentSystem) {
      _startMonitoring();
    }
  }

  /// Start monitoring for talent choice requirements
  void _startMonitoring() {
    if (_isMonitoring || _controller == null) return;

    _isMonitoring = true;
    _controller!.addListener(_onControllerUpdate);

    // Check immediately
    _checkForTalentChoice();
  }

  /// Handle controller updates
  void _onControllerUpdate() {
    if (!_isMonitoring || !useNewTalentSystem) return;
    _checkForTalentChoice();
  }

  /// Check if talent choice is needed and trigger dialog
  void _checkForTalentChoice() {
    if (_controller == null || _context == null) return;

    final state = _controller!.state;
    final user = _controller!.currentUser;

    if (hasLogDetailed) {
      debugPrint(
          'TalentTrigger: Checking talent choice - Level: ${user?.level}, Needs choice: ${state.needsTalentChoice}');
    }

    // Only check if we haven't already checked this level
    if (state.needsTalentChoice &&
        state.talentChoiceLevel != null &&
        _lastCheckedLevel != state.talentChoiceLevel) {
      _lastCheckedLevel = state.talentChoiceLevel;

      if (hasLogDetailed) {
        debugPrint(
            'TalentTrigger: Triggering talent choice for level ${state.talentChoiceLevel}');
      }

      // Create talent choice from controller state using existing system
      final talentChoice =
          UserTalents.getTalentChoice(state.talentChoiceLevel!);

      // Trigger dialog post-frame to avoid timing issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTalentDialog(talentChoice);
      });
    }
  }

  /// Show talent selection dialog
  Future<void> _showTalentDialog(TalentChoice talentChoice) async {
    if (_context == null || !_context!.mounted) return;

    try {
      if (hasLogDetailed) {
        debugPrint(
            'TalentTrigger: Showing talent dialog for level ${talentChoice.level}');
      }

      final selectedTalent = await TalentDialogService.instance
          .showTalentSelectionDialog(_context!, talentChoice);

      if (selectedTalent != null) {
        if (hasLogDetailed) {
          debugPrint('TalentTrigger: Talent selected: ${selectedTalent.name}');
        }

        _showTalentSuccess(selectedTalent);

        // Update last checked to prevent re-triggering
        _lastCheckedLevel = talentChoice.level;
      }
    } catch (e) {
      if (hasLogDetailed) {
        debugPrint('TalentTrigger: Error showing talent dialog: $e');
      }
    }
  }

  /// Show success message
  void _showTalentSuccess(UserTalent talent) {
    if (_context == null || !_context!.mounted) return;

    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Talent Unlocked!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    talent.name,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Force check for pending talent choices
  void checkPendingTalentChoices() {
    if (useNewTalentSystem) {
      _checkForTalentChoice();
    }
  }

  /// Stop monitoring
  void stopMonitoring() {
    if (_isMonitoring && _controller != null) {
      _controller!.removeListener(_onControllerUpdate);
      _isMonitoring = false;
    }
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _context = null;
    _controller = null;
    _lastCheckedLevel = null;
  }

  /// Get status for debugging
  Map<String, dynamic> getStatus() {
    return {
      'is_monitoring': _isMonitoring,
      'has_context': _context != null,
      'has_controller': _controller != null,
      'last_checked_level': _lastCheckedLevel,
      'using_new_system': useNewTalentSystem,
      'controller_state': _controller?.state.needsTalentChoice,
      'controller_level': _controller?.state.talentChoiceLevel,
    };
  }
}
