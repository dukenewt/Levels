import 'package:flutter/foundation.dart';
import '../models/specialization.dart';
import '../models/skill.dart';

class SpecializationProvider with ChangeNotifier {
  final Map<String, List<Specialization>> _specializations = {};

  SpecializationProvider() {
    _initializeSpecializations();
  }

  void _initializeSpecializations() {
    // Initialize specializations from templates
    SpecializationTemplates.templates.forEach((category, specs) {
      _specializations[category] = specs.map((spec) => Specialization(
        id: spec['id'],
        name: spec['name'],
        description: spec['description'],
        skillCategory: category,
        requiredLevel: spec['requiredLevel'],
        prerequisites: spec['prerequisites'] ?? [],
        bonuses: spec['bonuses'],
      )).toList();
    });
  }

  // Get all specializations for a category
  List<Specialization> getSpecializationsForCategory(String category) {
    return _specializations[category] ?? [];
  }

  // Get available specializations for a skill
  List<Specialization> getAvailableSpecializations(Skill skill) {
    final specs = _specializations[skill.category] ?? [];
    return specs.where((spec) => 
      !spec.isUnlocked && spec.canUnlock({
        'level': skill.level,
        'achievements': skill.achievements,
      })
    ).toList();
  }

  // Unlock a specialization for a skill
  Skill unlockSpecialization(Skill skill, String specializationId) {
    final specialization = _specializations[skill.category]?.firstWhere(
      (spec) => spec.id == specializationId,
      orElse: () => throw Exception('Specialization not found'),
    );

    if (specialization == null) {
      throw Exception('Specialization not found for category');
    }

    if (!specialization.canUnlock({
      'level': skill.level,
      'achievements': skill.achievements,
    })) {
      throw Exception('Cannot unlock specialization: requirements not met');
    }

    final updatedSpecializations = skill.specializations.map((spec) {
      if (spec.id == specializationId) {
        return spec.copyWith(isUnlocked: true);
      }
      return spec;
    }).toList();

    return skill.copyWith(specializations: updatedSpecializations);
  }

  // Activate a specialization for a skill
  Skill activateSpecialization(Skill skill, String specializationId) {
    final specialization = skill.specializations.firstWhere(
      (spec) => spec.id == specializationId,
      orElse: () => throw Exception('Specialization not found'),
    );

    if (!specialization.isUnlocked) {
      throw Exception('Cannot activate specialization: not unlocked');
    }

    return skill.copyWith(activeSpecializationId: specializationId);
  }

  // Get specialization details
  Specialization? getSpecialization(String category, String specializationId) {
    return _specializations[category]?.firstWhere(
      (spec) => spec.id == specializationId,
      orElse: () => throw Exception('Specialization not found'),
    );
  }

  // Check if a specialization is available for a skill
  bool isSpecializationAvailable(Skill skill, String specializationId) {
    final specialization = _specializations[skill.category]?.firstWhere(
      (spec) => spec.id == specializationId,
      orElse: () => throw Exception('Specialization not found'),
    );

    if (specialization == null) return false;

    return specialization.canUnlock({
      'level': skill.level,
      'achievements': skill.achievements,
    });
  }
} 