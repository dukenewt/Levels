import 'package:flutter/material.dart';
import '../providers/user_provider.dart';
import '../models/user_talent.dart';
import '../models/enhanced_user_perk.dart';
import '../services/talent_dialog_service.dart';

/// App-level talent manager that coordinates talent and perk systems
/// This service handles:
/// - Setting up talent choice callbacks
/// - Managing perk unlock notifications
/// - Coordinating with the UI layer
class AppTalentManager {
  static final AppTalentManager _instance = AppTalentManager._internal();
  static AppTalentManager get instance => _instance;
  
  AppTalentManager._internal();

  BuildContext? _context;
  UserProvider? _userProvider;
  
  /// Initialize the talent manager with app context and user provider
  void initialize(BuildContext context, UserProvider userProvider) {
    _context = context;
    _userProvider = userProvider;
    
    // Set up talent choice callback
    userProvider.onTalentChoice = _handleTalentChoice;
    userProvider.onPerkUnlock = _handlePerkUnlock;
  }

  /// Handle talent choice requirement
  Future<void> _handleTalentChoice(TalentChoice talentChoice) async {
    if (_context == null) return;
    // Show dialog post-frame to avoid navigation/timing races
    final ctx = _context!;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!ctx.mounted) return;
      final selectedTalent = await TalentDialogService.instance
          .showTalentSelectionDialog(ctx, talentChoice);
      if (selectedTalent != null) {
        _showTalentUnlockSuccess(selectedTalent);
      }
    });
  }

  /// Handle perk unlock notification
  void _handlePerkUnlock(EnhancedUserPerk perk) {
    if (_context == null) return;
    
    _showPerkUnlockNotification(perk);
  }

  /// Show talent unlock success message
  void _showTalentUnlockSuccess(UserTalent talent) {
    if (_context == null) return;
    
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Talent Unlocked!',
                    style: const TextStyle(
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

  /// Show perk unlock notification
  void _showPerkUnlockNotification(EnhancedUserPerk perk) {
    if (_context == null) return;
    
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.stars,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Perk Unlocked!',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    perk.name,
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
        backgroundColor: Colors.amber[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Check for pending talent choices on app start
  Future<void> checkPendingTalentChoices() async {
    if (_userProvider == null) return;
    
    await _userProvider!.checkPendingTalentChoices();
  }

  /// Dispose resources
  void dispose() {
    _context = null;
    _userProvider = null;
  }
}
