import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/skill.dart';
import '../models/skill_achievement.dart';

class SkillProvider with ChangeNotifier {
  List<Skill> _skills = [];
  Map<String, List<SkillAchievement>> _achievements = {};
  final String _storageKey = 'skills_data';
  final String _achievementsKey = 'skill_achievements';

  List<Skill> get skills => _skills;
  Map<String, List<SkillAchievement>> get achievements => _achievements;

  // Get skill by ID
  Skill? getSkillById(String id) {
    try {
      return _skills.firstWhere((skill) => skill.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get skills by category
  List<Skill> getSkillsByCategory(String category) {
    return _skills.where((skill) => skill.category == category).toList();
  }

  // Get overall level (average of all skill levels)
  double get overallLevel {
    if (_skills.isEmpty) return 1.0;
    return _skills.map((skill) => skill.level).reduce((a, b) => a + b) / _skills.length;
  }

  // Initialize default skills
  Future<void> initializeDefaultSkills() async {
    if (_skills.isNotEmpty) return;

    final now = DateTime.now();
    _skills = SkillCategories.categories.entries.map((entry) {
      return Skill(
        id: entry.key,
        name: entry.value,
        description: SkillCategories.descriptions[entry.key] ?? '',
        category: entry.key,
        createdAt: now,
        lastLevelUp: now,
      );
    }).toList();

    // Initialize achievements for each skill
    for (var skill in _skills) {
      _achievements[skill.id] = SkillAchievement.getAchievementsForSkill(skill.id);
    }

    await _saveSkills();
    await _saveAchievements();
    notifyListeners();
  }

  // Add XP to a skill
  Future<void> addXP(String skillId, int xp) async {
    final skillIndex = _skills.indexWhere((skill) => skill.id == skillId);
    if (skillIndex == -1) return;

    final skill = _skills[skillIndex];
    final updatedSkill = skill.addXP(xp);
    _skills[skillIndex] = updatedSkill;

    // Check for achievements
    await _checkAchievements(skillId, updatedSkill);

    await _saveSkills();
    notifyListeners();
  }

  // Check and unlock achievements
  Future<void> _checkAchievements(String skillId, Skill skill) async {
    final skillAchievements = _achievements[skillId] ?? [];
    for (var achievement in skillAchievements) {
      if (achievement.unlockedAt == null && achievement.isUnlocked(skill.level)) {
        // Unlock achievement
        final updatedAchievement = SkillAchievement(
          id: achievement.id,
          title: achievement.title,
          description: achievement.description,
          skillId: achievement.skillId,
          requiredLevel: achievement.requiredLevel,
          xpReward: achievement.xpReward,
          icon: achievement.icon,
          isSecret: achievement.isSecret,
          requirements: achievement.requirements,
          unlockedAt: DateTime.now(),
        );

        // Update achievement in the list
        final index = skillAchievements.indexWhere((a) => a.id == achievement.id);
        if (index != -1) {
          skillAchievements[index] = updatedAchievement;
        }

        // Add XP reward
        await addXP(skillId, achievement.xpReward);
      }
    }
    await _saveAchievements();
  }

  // Get unlocked achievements for a skill
  List<SkillAchievement> getUnlockedAchievements(String skillId) {
    final skillAchievements = _achievements[skillId] ?? [];
    return skillAchievements.where((a) => a.unlockedAt != null).toList();
  }

  // Get locked achievements for a skill
  List<SkillAchievement> getLockedAchievements(String skillId) {
    final skillAchievements = _achievements[skillId] ?? [];
    return skillAchievements.where((a) => a.unlockedAt == null && !a.isSecret).toList();
  }

  // Get skill tree progress
  Map<String, dynamic> getSkillTreeProgress(String skillId) {
    final skill = getSkillById(skillId);
    if (skill == null) return {};

    return {
      'novice': {
        'isUnlocked': skill.level >= 1,
        'isCompleted': skill.level >= 9,
        'progress': (skill.level - 1) / 8,
      },
      'apprentice': {
        'isUnlocked': skill.level >= 10,
        'isCompleted': skill.level >= 24,
        'progress': (skill.level - 10) / 14,
      },
      'expert': {
        'isUnlocked': skill.level >= 25,
        'isCompleted': skill.level >= 49,
        'progress': (skill.level - 25) / 24,
      },
      'master': {
        'isUnlocked': skill.level >= 50,
        'isCompleted': false,
        'progress': (skill.level - 50) / 50,
      },
    };
  }

  // Load skills from storage
  Future<void> loadSkills() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load skills
      final skillsJson = prefs.getString(_storageKey);
      if (skillsJson != null) {
        final List<dynamic> decodedSkills = json.decode(skillsJson);
        _skills = decodedSkills.map((skillJson) => Skill.fromJson(skillJson)).toList();
      }

      // Load achievements
      final achievementsJson = prefs.getString(_achievementsKey);
      if (achievementsJson != null) {
        final Map<String, dynamic> decodedAchievements = json.decode(achievementsJson);
        _achievements = decodedAchievements.map((key, value) {
          final List<dynamic> achievementsList = value as List<dynamic>;
          return MapEntry(
            key,
            achievementsList.map((a) => SkillAchievement.fromJson(a)).toList(),
          );
        });
      }

      if (_skills.isEmpty) {
        await initializeDefaultSkills();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading skills: $e');
      await initializeDefaultSkills();
    }
  }

  // Save skills to storage
  Future<void> _saveSkills() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final skillsJson = json.encode(_skills.map((skill) => skill.toJson()).toList());
      await prefs.setString(_storageKey, skillsJson);
    } catch (e) {
      debugPrint('Error saving skills: $e');
    }
  }

  // Save achievements to storage
  Future<void> _saveAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = json.encode(
        _achievements.map((key, value) => MapEntry(
          key,
          value.map((a) => a.toJson()).toList(),
        )),
      );
      await prefs.setString(_achievementsKey, achievementsJson);
    } catch (e) {
      debugPrint('Error saving achievements: $e');
    }
  }

  // Calculate XP for task difficulty
  static int calculateTaskXP(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return XPTiers.easy['min']! + (DateTime.now().millisecondsSinceEpoch % (XPTiers.easy['max']! - XPTiers.easy['min']!));
      case 'medium':
        return XPTiers.medium['min']! + (DateTime.now().millisecondsSinceEpoch % (XPTiers.medium['max']! - XPTiers.medium['min']!));
      case 'hard':
        return XPTiers.hard['min']! + (DateTime.now().millisecondsSinceEpoch % (XPTiers.hard['max']! - XPTiers.hard['min']!));
      case 'epic':
        return XPTiers.epic['min']! + (DateTime.now().millisecondsSinceEpoch % (XPTiers.epic['max']! - XPTiers.epic['min']!));
      default:
        return XPTiers.easy['min']!;
    }
  }

  // Add a custom skill
  Future<void> addCustomSkill({
    required String id,
    required String name,
    required String description,
    required String icon,
    required Color color,
  }) async {
    final now = DateTime.now();
    final skill = Skill(
      id: id,
      name: name,
      description: description,
      category: 'custom',
      createdAt: now,
      lastLevelUp: now,
      icon: icon,
      color: color,
    );

    _skills.add(skill);
    _achievements[skill.id] = SkillAchievement.getAchievementsForSkill(skill.id);
    
    await _saveSkills();
    await _saveAchievements();
    notifyListeners();
  }

  // Update a skill (for level up, point allocation, etc.)
  Future<void> updateSkill(Skill updatedSkill) async {
    final index = _skills.indexWhere((s) => s.id == updatedSkill.id);
    if (index != -1) {
      _skills[index] = updatedSkill;
      await _saveSkills();
      notifyListeners();
    }
  }
} 