import 'package:flutter/material.dart';
import 'user_rank.dart';

/// Data model that contains all information needed for a celebration
/// This separates the celebration data from how it's presented
class CelebrationData {
  final int oldLevel;
  final int newLevel;
  final String rankName;
  final Color rankColor;
  final List<String> unlockedPerks;
  final UserRank? newRank;
  final DateTime triggeredAt;

  CelebrationData({
    required this.oldLevel,
    required this.newLevel,
    required this.rankName,
    required this.rankColor,
    required this.unlockedPerks,
    this.newRank,
    DateTime? triggeredAt,
  }) : triggeredAt = triggeredAt ?? DateTime.now();

  /// Check if this is a major level milestone
  bool get isMajorMilestone {
    return newLevel % 10 == 0 || (newRank != null && oldLevel < newRank!.requiredLevel);
  }

  /// Get the level difference
  int get levelDifference => newLevel - oldLevel;

  /// Check if any perks were unlocked
  bool get hasUnlockedPerks => unlockedPerks.isNotEmpty;

  @override
  String toString() {
    return 'CelebrationData(oldLevel: $oldLevel, newLevel: $newLevel, rankName: $rankName, perks: ${unlockedPerks.length})';
  }
} 