import 'dart:convert';
import 'specialization.dart';
import 'package:flutter/material.dart';

class SkillPrerequisite {
  final String requiredSkillId;
  final int requiredLevel;

  SkillPrerequisite({
    required this.requiredSkillId,
    required this.requiredLevel,
  });

  Map<String, dynamic> toJson() => {
    'requiredSkillId': requiredSkillId,
    'requiredLevel': requiredLevel,
  };

  factory SkillPrerequisite.fromJson(Map<String, dynamic> json) => SkillPrerequisite(
    requiredSkillId: json['requiredSkillId'],
    requiredLevel: json['requiredLevel'],
  );
}

class Skill {
  final String id;
  final String name;
  final String description;
  final String category;
  final int level;
  final int currentXp;
  final int totalXP;
  final List<String> achievements;
  final DateTime createdAt;
  final DateTime lastLevelUp;
  final Map<String, dynamic> stats;
  final List<Specialization> specializations;
  final String? activeSpecializationId;
  final Color color;
  final String icon;
  final int availablePoints;
  final List<SkillPrerequisite> prerequisites;

  Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.level = 1,
    this.currentXp = 0,
    this.totalXP = 0,
    this.achievements = const [],
    required this.createdAt,
    required this.lastLevelUp,
    this.stats = const {},
    this.specializations = const [],
    this.activeSpecializationId,
    Color? color,
    String? icon,
    this.availablePoints = 0,
    this.prerequisites = const [],
  }) : color = color ?? _getDefaultColorForCategory(category),
       icon = icon ?? _getDefaultIconForCategory(category);

  // Get default color for category
  static Color _getDefaultColorForCategory(String category) {
    switch (category) {
      case 'health':
        return Colors.green;
      case 'learning':
        return Colors.blue;
      case 'career':
        return Colors.purple;
      case 'social':
        return Colors.orange;
      case 'creativity':
        return Colors.pink;
      case 'home':
        return Colors.brown;
      case 'finance':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  // Get default icon for category
  static String _getDefaultIconForCategory(String category) {
    switch (category) {
      case 'health':
        return 'fitness_center';
      case 'learning':
        return 'school';
      case 'career':
        return 'work';
      case 'social':
        return 'people';
      case 'creativity':
        return 'brush';
      case 'home':
        return 'home';
      case 'finance':
        return 'attach_money';
      default:
        return 'star';
    }
  }

  // Get active specialization
  Specialization? get activeSpecialization {
    if (activeSpecializationId == null) return null;
    return specializations.firstWhere(
      (spec) => spec.id == activeSpecializationId,
      orElse: () => throw Exception('Active specialization not found'),
    );
  }

  // Get available specializations based on current level and achievements
  List<Specialization> get availableSpecializations {
    final Map<String, dynamic> skillStats = {
      'level': level,
      'achievements': achievements,
    };
    
    return specializations.where((spec) => 
      !spec.isUnlocked && spec.canUnlock(skillStats)
    ).toList();
  }

  // Unlock a specialization
  Skill unlockSpecialization(String specializationId) {
    final specialization = specializations.firstWhere(
      (spec) => spec.id == specializationId,
      orElse: () => throw Exception('Specialization not found'),
    );

    if (!specialization.canUnlock({
      'level': level,
      'achievements': achievements,
    })) {
      throw Exception('Cannot unlock specialization: requirements not met');
    }

    final updatedSpecializations = specializations.map((spec) {
      if (spec.id == specializationId) {
        return spec.copyWith(isUnlocked: true);
      }
      return spec;
    }).toList();

    return copyWith(specializations: updatedSpecializations);
  }

  // Activate a specialization
  Skill activateSpecialization(String specializationId) {
    final specialization = specializations.firstWhere(
      (spec) => spec.id == specializationId,
      orElse: () => throw Exception('Specialization not found'),
    );

    if (!specialization.isUnlocked) {
      throw Exception('Cannot activate specialization: not unlocked');
    }

    return copyWith(activeSpecializationId: specializationId);
  }

  // Calculate XP multiplier based on active specialization
  double get xpMultiplier {
    if (activeSpecialization == null) return 1.0;
    return activeSpecialization!.bonuses['xpMultiplier'] ?? 1.0;
  }

  // Calculate XP needed for next level
  int get xpForNextLevel => level * 1000;

  double get progressPercentage {
    if (xpForNextLevel == 0) return 0;
    return (currentXp / xpForNextLevel) * 100;
  }

  // Calculate XP needed for a specific level
  static int xpForLevel(int level) {
    if (level < 10) {
      return (level - 1) * 1000;
    } else if (level < 25) {
      return 9000 + (level - 10) * 2000;
    } else if (level < 50) {
      return 39000 + (level - 25) * 5000;
    } else {
      return 164000 + (level - 50) * 10000;
    }
  }

  // Add XP and handle level up with specialization bonuses
  Skill addXP(int xp) {
    final modifiedXP = (xp * xpMultiplier).round();
    int newCurrentXp = currentXp + modifiedXP;
    int newTotalXP = totalXP + modifiedXP;
    int newLevel = level;
    DateTime newLastLevelUp = lastLevelUp;

    // Check for level up
    while (newCurrentXp >= xpForNextLevel) {
      newCurrentXp -= xpForNextLevel;
      newLevel++;
      newLastLevelUp = DateTime.now();
    }

    return copyWith(
      level: newLevel,
      currentXp: newCurrentXp,
      totalXP: newTotalXP,
      lastLevelUp: newLastLevelUp,
    );
  }

  // Get title based on level
  String get title {
    if (level >= 50) {
      return 'Master of $name';
    } else if (level >= 25) {
      return 'Expert in $name';
    } else if (level >= 10) {
      return 'Skilled in $name';
    } else {
      return 'Novice in $name';
    }
  }

  // Create a copy of the skill with updated fields
  Skill copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    int? level,
    int? currentXp,
    int? totalXP,
    List<String>? achievements,
    DateTime? createdAt,
    DateTime? lastLevelUp,
    Map<String, dynamic>? stats,
    List<Specialization>? specializations,
    String? activeSpecializationId,
    Color? color,
    String? icon,
    int? availablePoints,
    List<SkillPrerequisite>? prerequisites,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      totalXP: totalXP ?? this.totalXP,
      achievements: achievements ?? this.achievements,
      createdAt: createdAt ?? this.createdAt,
      lastLevelUp: lastLevelUp ?? this.lastLevelUp,
      stats: stats ?? this.stats,
      specializations: specializations ?? this.specializations,
      activeSpecializationId: activeSpecializationId ?? this.activeSpecializationId,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      availablePoints: availablePoints ?? this.availablePoints,
      prerequisites: prerequisites ?? this.prerequisites,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'level': level,
      'currentXp': currentXp,
      'totalXP': totalXP,
      'achievements': achievements,
      'createdAt': createdAt.toIso8601String(),
      'lastLevelUp': lastLevelUp.toIso8601String(),
      'stats': stats,
      'specializations': specializations.map((s) => s.toJson()).toList(),
      'activeSpecializationId': activeSpecializationId,
      'color': color.value,
      'icon': icon,
      'availablePoints': availablePoints,
      'prerequisites': prerequisites.map((p) => p.toJson()).toList(),
    };
  }

  // Create from JSON
  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      level: json['level'],
      currentXp: json['currentXp'],
      totalXP: json['totalXP'],
      achievements: List<String>.from(json['achievements']),
      createdAt: DateTime.parse(json['createdAt']),
      lastLevelUp: DateTime.parse(json['lastLevelUp']),
      stats: Map<String, dynamic>.from(json['stats']),
      specializations: (json['specializations'] as List)
          .map((s) => Specialization.fromJson(s))
          .toList(),
      activeSpecializationId: json['activeSpecializationId'],
      color: json['color'] != null ? Color(json['color']) : null,
      icon: json['icon'],
      availablePoints: json['availablePoints'] ?? 0,
      prerequisites: (json['prerequisites'] as List<dynamic>? ?? []).map((p) => SkillPrerequisite.fromJson(p)).toList(),
    );
  }
}

// Predefined skill categories
class SkillCategories {
  static const Map<String, String> categories = {
    'health': 'Health & Fitness',
    'learning': 'Learning',
    'career': 'Career',
    'social': 'Social',
    'creativity': 'Creativity',
    'home': 'Home & Organization',
    'finance': 'Finance',
  };

  static const Map<String, String> descriptions = {
    'health': 'Track your physical and mental well-being through exercise, meal prep, and medical appointments',
    'learning': 'Develop new knowledge and skills through reading, courses, practicing instruments, and languages',
    'career': 'Advance your professional growth through work projects, networking, and skill development',
    'social': 'Build and maintain meaningful relationships through calling friends, planning events, and community involvement',
    'creativity': 'Express yourself through art, writing, music, crafts, and side projects',
    'home': 'Create and maintain an organized living space through cleaning, maintenance, and decluttering',
    'finance': 'Manage and grow your financial resources through budgeting, investing research, and bill management',
  };
}

// XP tiers for different task difficulties
class XPTiers {
  static const Map<String, int> easy = {'min': 25, 'max': 50};
  static const Map<String, int> medium = {'min': 75, 'max': 150};
  static const Map<String, int> hard = {'min': 200, 'max': 400};
  static const Map<String, int> epic = {'min': 500, 'max': 1000};
} 