/// Controller for talent and perk effects state management
/// This owns the evaluated effects snapshot and publishes view state

import 'package:flutter/foundation.dart';
import '../models/effect.dart';
import '../models/user.dart';
import '../models/task.dart';
import '../models/enhanced_user_perk.dart';
import '../services/pure_effect_engine.dart';

/// View state for talent and perk effects
class TalentPerkViewState {
  final List<Effect> activeEffects;
  final Map<String, double> propertyModifiers;
  final Map<String, dynamic> conditionalValues;
  final Map<String, String> effectDescriptions;
  final List<EnhancedUserPerk> unlockedPerks;
  final List<String> availableTalents;
  final bool needsTalentChoice;
  final int? talentChoiceLevel;
  final bool isLoading;
  final String? error;
  final DateTime lastUpdated;
  
  const TalentPerkViewState({
    this.activeEffects = const [],
    this.propertyModifiers = const {},
    this.conditionalValues = const {},
    this.effectDescriptions = const {},
    this.unlockedPerks = const [],
    this.availableTalents = const [],
    this.needsTalentChoice = false,
    this.talentChoiceLevel,
    this.isLoading = false,
    this.error,
    required this.lastUpdated,
  });
  
  factory TalentPerkViewState.initial() {
    return TalentPerkViewState(
      lastUpdated: DateTime.now(),
    );
  }
  
  factory TalentPerkViewState.loading() {
    return TalentPerkViewState(
      isLoading: true,
      lastUpdated: DateTime.now(),
    );
  }
  
  factory TalentPerkViewState.error(String error) {
    return TalentPerkViewState(
      error: error,
      lastUpdated: DateTime.now(),
    );
  }
  
  TalentPerkViewState copyWith({
    List<Effect>? activeEffects,
    Map<String, double>? propertyModifiers,
    Map<String, dynamic>? conditionalValues,
    Map<String, String>? effectDescriptions,
    List<EnhancedUserPerk>? unlockedPerks,
    List<String>? availableTalents,
    bool? needsTalentChoice,
    int? talentChoiceLevel,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return TalentPerkViewState(
      activeEffects: activeEffects ?? this.activeEffects,
      propertyModifiers: propertyModifiers ?? this.propertyModifiers,
      conditionalValues: conditionalValues ?? this.conditionalValues,
      effectDescriptions: effectDescriptions ?? this.effectDescriptions,
      unlockedPerks: unlockedPerks ?? this.unlockedPerks,
      availableTalents: availableTalents ?? this.availableTalents,
      needsTalentChoice: needsTalentChoice ?? this.needsTalentChoice,
      talentChoiceLevel: talentChoiceLevel ?? this.talentChoiceLevel,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }
  
  /// Get XP multiplier for a specific category
  double getXPMultiplier({String? category}) {
    double multiplier = 1.0;
    
    // Apply global XP bonuses
    multiplier *= (propertyModifiers['xp'] ?? 1.0);
    
    // Apply category-specific bonuses if applicable
    if (category != null) {
      for (final effect in activeEffects) {
        if (effect.targetProperty == 'xp' && 
            effect.scope == EffectScope.category &&
            effect.conditions.any((c) => c.type == 'category' && c.value == category)) {
          multiplier += effect.value;
        }
      }
    }
    
    return multiplier;
  }
  
  /// Get loot box chance multiplier
  double getLootBoxMultiplier() {
    return propertyModifiers['loot_box_chance'] ?? 1.0;
  }
  
  /// Check if streak protection is available
  bool hasStreakProtection() {
    final freezeUses = conditionalValues['streak_freeze'] as double?;
    return freezeUses != null && freezeUses > 0;
  }
  
  /// Get effect preview for a category
  List<String> getEffectPreview(String category) {
    final previews = <String>[];
    
    for (final effect in activeEffects) {
      if (effect.targetProperty == 'xp') {
        if (effect.scope == EffectScope.global) {
          previews.add('+${(effect.value * 100).toInt()}% All XP');
        } else if (effect.scope == EffectScope.category &&
                   effect.conditions.any((c) => c.type == 'category' && c.value == category)) {
          previews.add('+${(effect.value * 100).toInt()}% $category XP');
        }
      } else if (effect.targetProperty == 'loot_box_chance') {
        previews.add('+${(effect.value * 100).toInt()}% Loot Box Chance');
      }
    }
    
    if (hasStreakProtection()) {
      previews.add('Streak Protection Available');
    }
    
    return previews;
  }
  
  /// Get summary of all active effects by category
  Map<String, List<String>> getEffectsByCategory() {
    final effectsByCategory = <String, List<String>>{};
    
    for (final effect in activeEffects) {
      String category = 'General';
      
      if (effect.scope == EffectScope.category) {
        final categoryCondition = effect.conditions
            .where((c) => c.type == 'category')
            .firstOrNull;
        if (categoryCondition != null) {
          category = categoryCondition.value as String;
        }
      }
      
      effectsByCategory[category] = effectsByCategory[category] ?? [];
      effectsByCategory[category]!.add(effect.description);
    }
    
    return effectsByCategory;
  }
}

/// Controller for managing talent and perk effects state
class TalentPerkController extends ChangeNotifier {
  TalentPerkViewState _state = TalentPerkViewState.initial();
  User? _currentUser;
  
  TalentPerkViewState get state => _state;
  User? get currentUser => _currentUser;
  
  /// Update the controller with new user data
  Future<void> updateUser(User user) async {
    if (_currentUser?.id == user.id && 
        _currentUser?.level == user.level &&
        _currentUser?.perks.length == user.perks.length &&
        _currentUser?.talents.length == user.talents.length) {
      // No significant changes, skip update
      return;
    }
    
    _currentUser = user;
    await _refreshEffects();
  }
  
  /// Refresh effects based on current user
  Future<void> _refreshEffects() async {
    if (_currentUser == null) {
      _setState(TalentPerkViewState.initial());
      return;
    }
    
    _setState(_state.copyWith(isLoading: true, error: null));
    
    try {
      // Evaluate effects for current user
      final effectContext = EffectContext.forPreview(
        category: 'General', // Use general context for state
        additional: {
          'user_level': _currentUser!.level,
        },
      );
      
      final effectResults = PureEffectEngine.evaluateEffects(
        user: _currentUser!,
        context: effectContext,
      );
      
      // Get unlocked perks
      final unlockedPerks = EnhancedUserPerks.getAvailablePerksForLevel(_currentUser!.level)
          .where((perk) => _currentUser!.perks.contains(perk.id) || 
                          perk.requiredLevel <= _currentUser!.level)
          .toList();
      
      // Check if talent choice is needed
      final needsTalentChoice = _checkNeedsTalentChoice(_currentUser!);
      final talentChoiceLevel = needsTalentChoice ? _getTalentChoiceLevel(_currentUser!) : null;
      
      // Get available talents
      final availableTalents = _getAvailableTalents(_currentUser!);
      
      _setState(TalentPerkViewState(
        activeEffects: effectResults.appliedEffects,
        propertyModifiers: effectResults.propertyModifiers,
        conditionalValues: effectResults.conditionalValues,
        effectDescriptions: effectResults.effectDescriptions,
        unlockedPerks: unlockedPerks,
        availableTalents: availableTalents,
        needsTalentChoice: needsTalentChoice,
        talentChoiceLevel: talentChoiceLevel,
        isLoading: false,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      _setState(TalentPerkViewState.error(e.toString()));
    }
  }
  
  /// Get effect preview for a specific context
  Future<List<String>> getEffectPreviewForContext({
    required String category,
    String difficulty = 'medium',
    Map<String, dynamic>? additionalContext,
  }) async {
    if (_currentUser == null) return [];
    
    try {
      return PureEffectEngine.getEffectPreview(
        user: _currentUser!,
        category: category,
        additionalContext: {
          'difficulty': difficulty,
          ...?additionalContext,
        },
      );
    } catch (e) {
      debugPrint('Error getting effect preview: $e');
      return [];
    }
  }
  
  /// Calculate XP preview for a task
  Future<int> calculateXPPreview({
    required int baseXP,
    required String category,
    required String difficulty,
    Map<String, dynamic>? additionalContext,
  }) async {
    if (_currentUser == null) return baseXP;
    
    try {
      final effectContext = EffectContext.forTask(
        category: category,
        difficulty: difficulty,
        additional: {
          'user_level': _currentUser!.level,
          ...?additionalContext,
        },
      );
      
      final effectResults = PureEffectEngine.evaluateEffects(
        user: _currentUser!,
        context: effectContext,
      );
      
      // Calculate total multiplier
      double totalMultiplier = 1.0;
      
      // Apply global XP bonus
      totalMultiplier *= effectResults.getMultiplier('xp');
      
      // Apply category-specific bonus
      for (final effect in effectResults.appliedEffects) {
        if (effect.targetProperty == 'xp' && 
            effect.scope == EffectScope.category &&
            effect.conditions.any((c) => c.type == 'category' && c.value == category)) {
          totalMultiplier += effect.value;
        }
      }
      
      return (baseXP * totalMultiplier).round();
    } catch (e) {
      debugPrint('Error calculating XP preview: $e');
      return baseXP;
    }
  }
  
  /// Force refresh effects
  Future<void> refresh() async {
    await _refreshEffects();
  }
  
  /// Clear controller state
  void clear() {
    _currentUser = null;
    _setState(TalentPerkViewState.initial());
  }
  
  void _setState(TalentPerkViewState newState) {
    _state = newState;
    notifyListeners();
  }
  
  /// Helper: check if user needs to make a talent choice
  bool _checkNeedsTalentChoice(User user) {
    final talentLevels = [5, 10, 15, 20, 25];
    
    for (final level in talentLevels) {
      if (user.level >= level && !user.talentChoices.containsKey(level)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Helper: get the level that needs a talent choice
  int? _getTalentChoiceLevel(User user) {
    final talentLevels = [5, 10, 15, 20, 25];
    
    for (final level in talentLevels) {
      if (user.level >= level && !user.talentChoices.containsKey(level)) {
        return level;
      }
    }
    
    return null;
  }
  
  /// Helper: get available talents for user
  List<String> _getAvailableTalents(User user) {
    final talents = <String>[];
    
    if (user.hasProjectManagementTalent()) {
      talents.add('Project Management');
    }
    
    if (user.hasNLPTalent()) {
      talents.add('Smart Categorization');
    }
    
    return talents;
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}

/// Extension to add convenience methods for accessing the controller
extension TalentPerkControllerExtension on TalentPerkController {
  /// Check if user has any effects that affect the given category
  bool hasEffectsForCategory(String category) {
    return state.activeEffects.any((effect) =>
        effect.scope == EffectScope.global ||
        (effect.scope == EffectScope.category &&
         effect.conditions.any((c) => c.type == 'category' && c.value == category)));
  }
  
  /// Get total XP multiplier for the given category
  double getTotalXPMultiplier(String category) {
    return state.getXPMultiplier(category: category);
  }
  
  /// Check if user has project management talent
  bool hasProjectManagement() {
    return currentUser?.hasProjectManagementTalent() ?? false;
  }
  
  /// Check if user has NLP talent
  bool hasSmartCategorization() {
    return currentUser?.hasNLPTalent() ?? false;
  }
  
  /// Get perk summary for profile display
  Map<String, dynamic> getPerkSummary() {
    final summary = state.getEffectsByCategory();
    return {
      'categoryEffects': summary,
      'totalPerks': state.unlockedPerks.length,
      'activeEffects': state.activeEffects.length,
      'hasStreakProtection': state.hasStreakProtection(),
      'lootBoxMultiplier': state.getLootBoxMultiplier(),
    };
  }
}