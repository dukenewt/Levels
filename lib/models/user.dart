import 'package:flutter/material.dart';
import 'user_rank.dart';

class User {
  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final int level;
  final int currentXp;
  final String rank;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.lastLoginAt,
    this.level = 1,
    this.currentXp = 0,
    String? rank,
  }) : rank = rank ?? UserRank.getRankForLevel(level).name;

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    int? level,
    int? currentXp,
    String? rank,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      rank: rank ?? UserRank.getRankForLevel(level ?? this.level).name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'level': level,
      'currentXp': currentXp,
      'rank': rank,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
      level: json['level'] as int,
      currentXp: json['currentXp'] as int,
      rank: json['rank'] as String?,
    );
  }
} 