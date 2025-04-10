import 'package:flutter/material.dart';
import '../models/skill.dart';

class SkillProvider extends ChangeNotifier {
  final Map<String, Skill> _skills = {
    'work': Skill(
      id: 'work',
      name: 'Work',
      description: 'Professional skills and work-related tasks',
      xpToNextLevel: 500,
      icon: 'work',
      color: const Color(0xFF78A1E8),
    ),
    'school': Skill(
      id: 'school',
      name: 'School',
      description: 'Academic achievements and study progress',
      xpToNextLevel: 500,
      icon: 'school',
      color: const Color(0xFF4CAF50),
    ),
    'exercise': Skill(
      id: 'exercise',
      name: 'Exercise',
      description: 'Physical fitness and health goals',
      xpToNextLevel: 500,
      icon: 'fitness_center',
      color: const Color(0xFFF5AC3D),
    ),
  };

  Map<String, Skill> get skills => _skills;

  int calculateXpForNextLevel(int currentLevel) {
    // Modified XP curve: Each level requires 1.2x more XP than the previous
    // Starting at 500 XP for level 1
    return (500 * (1.2 * currentLevel)).round();
  }

  void addXpToSkill(String skillId, int xpAmount) {
    if (!_skills.containsKey(skillId)) return;

    final skill = _skills[skillId]!;
    int newXp = skill.currentXp + xpAmount;
    int newLevel = skill.level;
    int xpToNextLevel = skill.xpToNextLevel;

    // Level up if enough XP is gained
    while (newXp >= xpToNextLevel) {
      newXp -= xpToNextLevel;
      newLevel++;
      xpToNextLevel = calculateXpForNextLevel(newLevel);
    }

    _skills[skillId] = skill.copyWith(
      level: newLevel,
      currentXp: newXp,
      xpToNextLevel: xpToNextLevel,
    );

    notifyListeners();
  }

  void addCustomSkill({
    required String id,
    required String name,
    required String description,
    required String icon,
    required Color color,
  }) {
    if (_skills.containsKey(id)) return;

    _skills[id] = Skill(
      id: id,
      name: name,
      description: description,
      xpToNextLevel: 1000,
      icon: icon,
      color: color,
    );

    notifyListeners();
  }

  void removeSkill(String skillId) {
    if (!_skills.containsKey(skillId)) return;
    _skills.remove(skillId);
    notifyListeners();
  }

  Skill? getSkill(String skillId) {
    return _skills[skillId];
  }

  List<Skill> getSkillsList() {
    return _skills.values.toList();
  }
} 