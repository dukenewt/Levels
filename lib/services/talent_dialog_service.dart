import 'package:flutter/material.dart';
import '../models/user_talent.dart';
import '../widgets/talent_selection_dialog.dart';

/// Service for managing talent selection dialogs
/// Handles showing forced talent choice dialogs when users reach talent levels
class TalentDialogService {
  static final TalentDialogService _instance = TalentDialogService._internal();
  static TalentDialogService get instance => _instance;

  TalentDialogService._internal();

  bool _isDialogShowing = false;

  /// Show talent selection dialog - returns the selected talent
  Future<UserTalent?> showTalentSelectionDialog(
    BuildContext context,
    TalentChoice talentChoice,
  ) async {
    if (_isDialogShowing) return null;

    _isDialogShowing = true;

    try {
      final selectedTalent = await showDialog<UserTalent>(
        context: context,
        barrierDismissible: false, // Must make a choice
        builder: (context) => TalentSelectionDialog(talentChoice: talentChoice),
      );

      return selectedTalent;
    } finally {
      _isDialogShowing = false;
    }
  }

  /// Check if a talent dialog is currently showing
  bool get isDialogShowing => _isDialogShowing;
}
