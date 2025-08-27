import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'user_rank.dart';
import 'user_talent.dart';

class User {
  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final int level;
  final int currentXp;
  final String rank;
  final String? profilePictureUrl;
  final List<String> perks;
  final List<String> talents; // List of unlocked talent IDs
  final Map<int, String> talentChoices; // Level -> selected talent ID mapping

  User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.lastLoginAt,
    this.level = 1,
    this.currentXp = 0,
    String? rank,
    this.profilePictureUrl,
    this.perks = const [],
    this.talents = const [],
    this.talentChoices = const {},
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
    String? profilePictureUrl,
    List<String>? perks,
    List<String>? talents,
    Map<int, String>? talentChoices,
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
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      perks: perks ?? this.perks,
      talents: talents ?? this.talents,
      talentChoices: talentChoices ?? this.talentChoices,
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
      'profilePictureUrl': profilePictureUrl,
      'perks': perks,
      'talents': talents,
      'talentChoices':
          talentChoices.map((key, value) => MapEntry(key.toString(), value)),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Parse talent choices map
    Map<int, String> parsedTalentChoices = {};
    if (json['talentChoices'] != null) {
      final talentChoicesMap = json['talentChoices'] as Map<String, dynamic>;
      for (var entry in talentChoicesMap.entries) {
        parsedTalentChoices[int.parse(entry.key)] = entry.value as String;
      }
    }

    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
      level: json['level'] as int,
      currentXp: json['currentXp'] as int,
      rank: json['rank'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      perks: json['perks'] != null ? List<String>.from(json['perks']) : [],
      talents:
          json['talents'] != null ? List<String>.from(json['talents']) : [],
      talentChoices: parsedTalentChoices,
    );
  }

  // Talent utility methods
  bool hasTalent(String talentId) => talents.contains(talentId);

  bool hasTalentType(TalentType talentType) {
    return talents.any((talentId) => talentId.startsWith(talentType.id));
  }

  bool hasProjectManagementTalent() =>
      hasTalentType(TalentType.projectManagement);

  bool hasNLPTalent() => hasTalentType(TalentType.nlpCategorization);

  bool needsTalentChoice() {
    return UserTalents.isTalentLevel(level) &&
        !talentChoices.containsKey(level);
  }

  List<int> getPendingTalentLevels() {
    return UserTalents.talentLevels
        .where(
            (level) => level <= this.level && !talentChoices.containsKey(level))
        .toList();
  }

  TalentChoice? getAvailableTalentChoice() {
    if (!needsTalentChoice()) return null;
    return UserTalents.getTalentChoice(level);
  }
}
