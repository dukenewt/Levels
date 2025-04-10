import 'package:flutter/material.dart';

class UserRank {
  final String name;
  final String title;
  final int requiredLevel;
  final Color color;
  final String description;
  final String icon;

  const UserRank({
    required this.name,
    required this.title,
    required this.requiredLevel,
    required this.color,
    required this.description,
    required this.icon,
  });

  static const List<UserRank> ranks = [
    UserRank(
      name: 'Novice',
      title: 'The Beginner',
      requiredLevel: 1,
      color: Color(0xFFB0BEC5), // Grey
      description: 'Just starting your journey',
      icon: 'emoji_events',
    ),
    UserRank(
      name: 'Apprentice',
      title: 'The Learner',
      requiredLevel: 5,
      color: Color(0xFF4CAF50), // Green
      description: 'Making steady progress',
      icon: 'school',
    ),
    UserRank(
      name: 'Adept',
      title: 'The Skilled',
      requiredLevel: 10,
      color: Color(0xFF2196F3), // Blue
      description: 'Mastering the basics',
      icon: 'psychology',
    ),
    UserRank(
      name: 'Expert',
      title: 'The Master',
      requiredLevel: 20,
      color: Color(0xFF9C27B0), // Purple
      description: 'Highly accomplished',
      icon: 'military_tech',
    ),
    UserRank(
      name: 'Legend',
      title: 'The Legendary',
      requiredLevel: 30,
      color: Color(0xFFF44336), // Red
      description: 'Among the greatest',
      icon: 'stars',
    ),
  ];

  static UserRank getRankForLevel(int level) {
    for (int i = ranks.length - 1; i >= 0; i--) {
      if (level >= ranks[i].requiredLevel) {
        return ranks[i];
      }
    }
    return ranks.first;
  }

  static UserRank? getNextRank(int currentLevel) {
    for (var rank in ranks) {
      if (rank.requiredLevel > currentLevel) {
        return rank;
      }
    }
    return null;
  }
} 