class User {
  final String id;
  final String email;
  final String displayName;
  final int level;
  final int currentXp;
  final List<String> achievements;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    this.level = 1,
    this.currentXp = 0,
    this.achievements = const [],
    required this.createdAt,
    required this.lastLoginAt,
  });

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    int? level,
    int? currentXp,
    List<String>? achievements,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      achievements: achievements ?? this.achievements,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'level': level,
      'currentXp': currentXp,
      'achievements': achievements,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      level: json['level'] as int,
      currentXp: json['currentXp'] as int,
      achievements: List<String>.from(json['achievements'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
    );
  }
} 