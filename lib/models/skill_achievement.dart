import 'package:flutter/material.dart';

class SkillAchievement {
  final String id;
  final String title;
  final String description;
  final String skillId;
  final int requiredLevel;
  final int xpReward;
  final String icon;
  final bool isSecret;
  final Map<String, dynamic> requirements;
  final DateTime? unlockedAt;

  SkillAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.skillId,
    required this.requiredLevel,
    required this.xpReward,
    required this.icon,
    this.isSecret = false,
    required this.requirements,
    this.unlockedAt,
  });

  bool isUnlocked(int currentLevel) {
    return currentLevel >= requiredLevel;
  }

  // Predefined achievements for each skill category
  static List<SkillAchievement> getAchievementsForSkill(String skillId) {
    switch (skillId) {
      case 'health':
        return [
          SkillAchievement(
            id: 'health_1',
            title: 'First Steps',
            description: 'Complete your first health-related task',
            skillId: 'health',
            requiredLevel: 1,
            xpReward: 100,
            icon: '🏃',
            requirements: {'tasks_completed': 1},
          ),
          SkillAchievement(
            id: 'health_2',
            title: 'Fitness Enthusiast',
            description: 'Complete 10 health-related tasks',
            skillId: 'health',
            requiredLevel: 5,
            xpReward: 500,
            icon: '💪',
            requirements: {'tasks_completed': 10},
          ),
          SkillAchievement(
            id: 'health_3',
            title: 'Wellness Warrior',
            description: 'Complete 50 health-related tasks',
            skillId: 'health',
            requiredLevel: 15,
            xpReward: 1000,
            icon: '🏆',
            requirements: {'tasks_completed': 50},
          ),
        ];
      case 'learning':
        return [
          SkillAchievement(
            id: 'learning_1',
            title: 'Curious Mind',
            description: 'Complete your first learning task',
            skillId: 'learning',
            requiredLevel: 1,
            xpReward: 100,
            icon: '📚',
            requirements: {'tasks_completed': 1},
          ),
          SkillAchievement(
            id: 'learning_2',
            title: 'Knowledge Seeker',
            description: 'Complete 10 learning tasks',
            skillId: 'learning',
            requiredLevel: 5,
            xpReward: 500,
            icon: '🎓',
            requirements: {'tasks_completed': 10},
          ),
          SkillAchievement(
            id: 'learning_3',
            title: 'Lifelong Learner',
            description: 'Complete 50 learning tasks',
            skillId: 'learning',
            requiredLevel: 15,
            xpReward: 1000,
            icon: '🎯',
            requirements: {'tasks_completed': 50},
          ),
        ];
      case 'career':
        return [
          SkillAchievement(
            id: 'career_1',
            title: 'Professional Start',
            description: 'Complete your first career task',
            skillId: 'career',
            requiredLevel: 1,
            xpReward: 100,
            icon: '💼',
            requirements: {'tasks_completed': 1},
          ),
          SkillAchievement(
            id: 'career_2',
            title: 'Career Builder',
            description: 'Complete 10 career tasks',
            skillId: 'career',
            requiredLevel: 5,
            xpReward: 500,
            icon: '📈',
            requirements: {'tasks_completed': 10},
          ),
          SkillAchievement(
            id: 'career_3',
            title: 'Career Master',
            description: 'Complete 50 career tasks',
            skillId: 'career',
            requiredLevel: 15,
            xpReward: 1000,
            icon: '🏢',
            requirements: {'tasks_completed': 50},
          ),
        ];
      // Add more skill categories...
      default:
        return [];
    }
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'skillId': skillId,
      'requiredLevel': requiredLevel,
      'xpReward': xpReward,
      'icon': icon,
      'isSecret': isSecret,
      'requirements': requirements,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory SkillAchievement.fromJson(Map<String, dynamic> json) {
    return SkillAchievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      skillId: json['skillId'],
      requiredLevel: json['requiredLevel'],
      xpReward: json['xpReward'],
      icon: json['icon'],
      isSecret: json['isSecret'] ?? false,
      requirements: Map<String, dynamic>.from(json['requirements']),
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
    );
  }
} 