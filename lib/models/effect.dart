/// Normalized effect system for TaskBound
/// This replaces the scattered effect logic with a unified model

/// Defines where an effect applies
enum EffectScope {
  global, // Applies to all tasks/activities
  category, // Applies to specific task categories
  task, // Applies to specific tasks
  context; // Applies based on context (time, streak, etc.)

  String get id {
    return name;
  }
}

/// Defines how an effect modifies values
enum EffectModifier {
  additive, // Adds a flat amount (+10 XP)
  multiplicative, // Multiplies by percentage (+15%)
  override, // Replaces the value entirely
  conditional; // Applies only if conditions are met

  String get id {
    return name;
  }
}

/// Defines when/how effects stack with others
enum EffectStacking {
  none, // Only one effect of this type applies
  additive, // Multiple effects add together (+10% + 15% = +25%)
  multiplicative, // Multiple effects multiply (1.1 * 1.15 = 1.265)
  highest, // Only the highest value applies
  latest; // Only the most recently applied effect counts

  String get id {
    return name;
  }
}

/// Duration/persistence of an effect
enum EffectDuration {
  permanent, // Always active once unlocked
  session, // Active for current app session
  task, // Active for single task completion
  streak, // Active while maintaining streak
  temporary; // Has explicit start/end times

  String get id {
    return name;
  }
}

/// Conditions that must be met for effect to apply
class EffectCondition {
  final String type; // 'category', 'difficulty', 'time', 'streak', etc.
  final String operator; // 'equals', 'greater_than', 'contains', etc.
  final dynamic value; // The value to compare against
  final bool inverted; // Whether to invert the condition

  const EffectCondition({
    required this.type,
    required this.operator,
    required this.value,
    this.inverted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'operator': operator,
      'value': value,
      'inverted': inverted,
    };
  }

  factory EffectCondition.fromJson(Map<String, dynamic> json) {
    return EffectCondition(
      type: json['type'] as String,
      operator: json['operator'] as String,
      value: json['value'],
      inverted: json['inverted'] as bool? ?? false,
    );
  }

  /// Check if this condition is met given the context
  bool isMet(Map<String, dynamic> context) {
    final contextValue = context[type];
    bool result = false;

    switch (operator) {
      case 'equals':
        result = contextValue == value;
        break;
      case 'not_equals':
        result = contextValue != value;
        break;
      case 'greater_than':
        result = (contextValue as num?) != null &&
            (contextValue as num) > (value as num);
        break;
      case 'greater_than_or_equal':
      case '>=':
        result = (contextValue as num?) != null &&
            (contextValue as num) >= (value as num);
        break;
      case 'less_than':
        result = (contextValue as num?) != null &&
            (contextValue as num) < (value as num);
        break;
      case 'less_than_or_equal':
      case '<=':
        result = (contextValue as num?) != null &&
            (contextValue as num) <= (value as num);
        break;
      case 'contains':
        result = contextValue
                ?.toString()
                .toLowerCase()
                .contains(value.toString().toLowerCase()) ??
            false;
        break;
      case 'in_list':
        result = (value as List?)?.contains(contextValue) ?? false;
        break;
      default:
        result = false;
    }

    return inverted ? !result : result;
  }
}

/// Unified effect model that replaces all scattered effect logic
class Effect {
  final String id; // Unique identifier
  final String name; // Human-readable name
  final String description; // Description for UI
  final EffectScope scope; // Where this effect applies
  final EffectModifier modifier; // How this effect modifies values
  final EffectStacking stacking; // How this effect stacks
  final EffectDuration duration; // How long this effect lasts
  final double value; // The effect value
  final String?
      targetProperty; // What property this affects (xp, loot_chance, etc.)
  final List<EffectCondition> conditions; // When this effect applies
  final Map<String, dynamic> metadata; // Additional effect data
  final DateTime? createdAt; // When effect was created
  final DateTime? expiresAt; // When effect expires (for temporary)

  const Effect({
    required this.id,
    required this.name,
    required this.description,
    required this.scope,
    required this.modifier,
    required this.stacking,
    required this.duration,
    required this.value,
    this.targetProperty,
    this.conditions = const [],
    this.metadata = const {},
    this.createdAt,
    this.expiresAt,
  });

  /// Create an XP bonus effect
  factory Effect.xpBonus({
    required String id,
    required String name,
    required double bonusPercentage,
    EffectScope scope = EffectScope.global,
    String? category,
    List<EffectCondition> conditions = const [],
  }) {
    final effectConditions = <EffectCondition>[...conditions];

    // Add category condition if specified
    if (category != null) {
      effectConditions.add(EffectCondition(
        type: 'category',
        operator: 'equals',
        value: category,
      ));
    }

    return Effect(
      id: id,
      name: name,
      description: scope == EffectScope.category && category != null
          ? '+${(bonusPercentage * 100).toInt()}% XP for $category tasks'
          : '+${(bonusPercentage * 100).toInt()}% XP for all tasks',
      scope: scope,
      modifier: EffectModifier.multiplicative,
      stacking: EffectStacking.additive,
      duration: EffectDuration.permanent,
      value: bonusPercentage,
      targetProperty: 'xp',
      conditions: effectConditions,
    );
  }

  /// Create a loot box bonus effect
  factory Effect.lootBoxBonus({
    required String id,
    required String name,
    required double bonusPercentage,
    List<EffectCondition> conditions = const [],
  }) {
    return Effect(
      id: id,
      name: name,
      description: '+${(bonusPercentage * 100).toInt()}% Loot Box Chance',
      scope: EffectScope.global,
      modifier: EffectModifier.additive,
      stacking: EffectStacking.additive,
      duration: EffectDuration.permanent,
      value: bonusPercentage,
      targetProperty: 'loot_box_chance',
      conditions: conditions,
    );
  }

  /// Create a streak protection effect
  factory Effect.streakFreeze({
    required String id,
    required String name,
    int uses = 1,
    List<EffectCondition> conditions = const [],
  }) {
    return Effect(
      id: id,
      name: name,
      description: uses == 1
          ? 'One-time streak protection'
          : '$uses streak protection uses',
      scope: EffectScope.context,
      modifier: EffectModifier.conditional,
      stacking: EffectStacking.additive,
      duration: EffectDuration.permanent,
      value: uses.toDouble(),
      targetProperty: 'streak_freeze',
      conditions: conditions,
      metadata: {'uses': uses, 'remaining_uses': uses},
    );
  }

  /// Create a conditional XP bonus effect
  factory Effect.conditionalXpBonus({
    required String id,
    required String name,
    required double bonusPercentage,
    required List<String> conditions,
  }) {
    final effectConditions = <EffectCondition>[];

    // Parse condition strings like "difficulty:easy", "recurring:true", "daily_categories_count:>=3"
    for (final conditionStr in conditions) {
      final parts = conditionStr.split(':');
      if (parts.length == 2) {
        final type = parts[0];
        var value = parts[1];
        String operator = 'equals';

        // Check for operators in the value part
        if (value.startsWith('>=')) {
          operator = '>=';
          value = value.substring(2);
        } else if (value.startsWith('<=')) {
          operator = '<=';
          value = value.substring(2);
        } else if (value.startsWith('>')) {
          operator = 'greater_than';
          value = value.substring(1);
        } else if (value.startsWith('<')) {
          operator = 'less_than';
          value = value.substring(1);
        }

        // Convert string values to appropriate types
        dynamic conditionValue = value;
        if (value == 'true')
          conditionValue = true;
        else if (value == 'false')
          conditionValue = false;
        else if (int.tryParse(value) != null)
          conditionValue = int.parse(value);
        else if (double.tryParse(value) != null)
          conditionValue = double.parse(value);

        effectConditions.add(EffectCondition(
          type: type,
          operator: operator,
          value: conditionValue,
        ));
      }
    }

    return Effect(
      id: id,
      name: name,
      description:
          '+${(bonusPercentage * 100).toInt()}% XP for ${_formatConditions(conditions)}',
      scope: EffectScope.context,
      modifier: EffectModifier.multiplicative,
      stacking: EffectStacking.additive,
      duration: EffectDuration.permanent,
      value: bonusPercentage,
      targetProperty: 'xp',
      conditions: effectConditions,
      metadata: {'conditionStrings': conditions},
    );
  }

  /// Helper to format condition strings for description
  static String _formatConditions(List<String> conditions) {
    return conditions.map((c) {
      final parts = c.split(':');
      if (parts.length == 2) {
        final type = parts[0];
        final value = parts[1];

        switch (type) {
          case 'difficulty':
            return '$value difficulty';
          case 'recurring':
            return value == 'true' ? 'recurring' : 'non-recurring';
          case 'category':
            return '$value category';
          default:
            return '$type:$value';
        }
      }
      return c;
    }).join(' ');
  }

  /// Check if this effect applies to the given context
  bool appliesTo(Map<String, dynamic> context) {
    // Check if effect has expired
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) {
      return false;
    }

    // Check all conditions
    return conditions.every((condition) => condition.isMet(context));
  }

  /// Apply this effect to a base value
  double applyTo(double baseValue, Map<String, dynamic> context) {
    if (!appliesTo(context)) {
      return baseValue;
    }

    switch (modifier) {
      case EffectModifier.additive:
        return baseValue + value;
      case EffectModifier.multiplicative:
        return baseValue * (1.0 + value);
      case EffectModifier.override:
        return value;
      case EffectModifier.conditional:
        // For conditional effects, return the effect value if conditions are met
        return value;
    }
  }

  /// Get a copy of this effect with updated metadata
  Effect copyWith({
    String? id,
    String? name,
    String? description,
    EffectScope? scope,
    EffectModifier? modifier,
    EffectStacking? stacking,
    EffectDuration? duration,
    double? value,
    String? targetProperty,
    List<EffectCondition>? conditions,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return Effect(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      scope: scope ?? this.scope,
      modifier: modifier ?? this.modifier,
      stacking: stacking ?? this.stacking,
      duration: duration ?? this.duration,
      value: value ?? this.value,
      targetProperty: targetProperty ?? this.targetProperty,
      conditions: conditions ?? this.conditions,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'scope': scope.id,
      'modifier': modifier.id,
      'stacking': stacking.id,
      'duration': duration.id,
      'value': value,
      'targetProperty': targetProperty,
      'conditions': conditions.map((c) => c.toJson()).toList(),
      'metadata': metadata,
      'createdAt': createdAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory Effect.fromJson(Map<String, dynamic> json) {
    return Effect(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      scope: EffectScope.values.firstWhere(
        (s) => s.id == json['scope'],
        orElse: () => EffectScope.global,
      ),
      modifier: EffectModifier.values.firstWhere(
        (m) => m.id == json['modifier'],
        orElse: () => EffectModifier.additive,
      ),
      stacking: EffectStacking.values.firstWhere(
        (s) => s.id == json['stacking'],
        orElse: () => EffectStacking.none,
      ),
      duration: EffectDuration.values.firstWhere(
        (d) => d.id == json['duration'],
        orElse: () => EffectDuration.permanent,
      ),
      value: (json['value'] as num).toDouble(),
      targetProperty: json['targetProperty'] as String?,
      conditions: (json['conditions'] as List<dynamic>?)
              ?.map((c) => EffectCondition.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Effect && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Effect(id: $id, name: $name, scope: $scope, value: $value)';
  }
}

/// Helper class for building context maps for effect evaluation
class EffectContext {
  static Map<String, dynamic> forTask({
    required String category,
    required String difficulty,
    int? streak,
    DateTime? completionTime,
    Map<String, dynamic>? additional,
  }) {
    final context = <String, dynamic>{
      'category': category,
      'difficulty': difficulty,
    };

    if (streak != null) context['streak'] = streak;
    if (completionTime != null) {
      context['completion_time'] = completionTime;
      context['hour'] = completionTime.hour;
      context['is_morning'] = completionTime.hour < 12;
      context['is_weekend'] = completionTime.weekday > 5;
    }

    if (additional != null) {
      context.addAll(additional);
    }

    return context;
  }

  static Map<String, dynamic> forPreview({
    required String category,
    Map<String, dynamic>? additional,
  }) {
    final context = <String, dynamic>{
      'category': category,
      'difficulty': 'medium',
      'streak': 1,
      'completion_time': DateTime.now(),
    };

    if (additional != null) {
      context.addAll(additional);
    }

    return context;
  }
}
