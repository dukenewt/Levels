import 'package:flutter/material.dart';

class Skill {
  final String id;
  final String name;
  final String description;
  final int level;
  final int currentXp;
  final int xpToNextLevel;
  final String icon;
  final Color color;

  Skill({
    required this.id,
    required this.name,
    required this.description,
    this.level = 1,
    this.currentXp = 0,
    required this.xpToNextLevel,
    required this.icon,
    required this.color,
  });

  double get progressPercentage => (currentXp / xpToNextLevel) * 100;

  Skill copyWith({
    String? id,
    String? name,
    String? description,
    int? level,
    int? currentXp,
    int? xpToNextLevel,
    String? icon,
    Color? color,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'level': level,
      'currentXp': currentXp,
      'xpToNextLevel': xpToNextLevel,
      'icon': icon,
      'color': color.value,
    };
  }

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      level: json['level'] as int,
      currentXp: json['currentXp'] as int,
      xpToNextLevel: json['xpToNextLevel'] as int,
      icon: json['icon'] as String,
      color: Color(json['color'] as int),
    );
  }
} 