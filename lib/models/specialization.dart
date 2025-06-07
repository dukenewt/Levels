// import 'dart:convert';

// class Specialization {
//   final String id;
//   final String name;
//   final String description;
//   final String skillCategory;
//   final int requiredLevel;
//   final List<String> prerequisites;
//   final Map<String, dynamic> bonuses;
//   final bool isUnlocked;
//   final DateTime unlockedAt;

//   Specialization({
//     required this.id,
//     required this.name,
//     required this.description,
//     required this.skillCategory,
//     required this.requiredLevel,
//     this.prerequisites = const [],
//     required this.bonuses,
//     this.isUnlocked = false,
//     DateTime? unlockedAt,
//   }) : unlockedAt = unlockedAt ?? DateTime.now();

//   // Check if a skill meets the requirements for this specialization
//   bool canUnlock(Map<String, dynamic> skillStats) {
//     if (skillStats['level'] < requiredLevel) return false;
    
//     for (String prereq in prerequisites) {
//       if (!skillStats['achievements'].contains(prereq)) return false;
//     }
    
//     return true;
//   }

//   // Create a copy with updated fields
//   Specialization copyWith({
//     String? id,
//     String? name,
//     String? description,
//     String? skillCategory,
//     int? requiredLevel,
//     List<String>? prerequisites,
//     Map<String, dynamic>? bonuses,
//     bool? isUnlocked,
//     DateTime? unlockedAt,
//   }) {
//     return Specialization(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       description: description ?? this.description,
//       skillCategory: skillCategory ?? this.skillCategory,
//       requiredLevel: requiredLevel ?? this.requiredLevel,
//       prerequisites: prerequisites ?? this.prerequisites,
//       bonuses: bonuses ?? this.bonuses,
//       isUnlocked: isUnlocked ?? this.isUnlocked,
//       unlockedAt: unlockedAt ?? this.unlockedAt,
//     );
//   }

//   // Convert to JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'description': description,
//       'skillCategory': skillCategory,
//       'requiredLevel': requiredLevel,
//       'prerequisites': prerequisites,
//       'bonuses': bonuses,
//       'isUnlocked': isUnlocked,
//       'unlockedAt': unlockedAt.toIso8601String(),
//     };
//   }

//   // Create from JSON
//   factory Specialization.fromJson(Map<String, dynamic> json) {
//     return Specialization(
//       id: json['id'],
//       name: json['name'],
//       description: json['description'],
//       skillCategory: json['skillCategory'],
//       requiredLevel: json['requiredLevel'],
//       prerequisites: List<String>.from(json['prerequisites']),
//       bonuses: Map<String, dynamic>.from(json['bonuses']),
//       isUnlocked: json['isUnlocked'],
//       unlockedAt: DateTime.parse(json['unlockedAt']),
//     );
//   }
// }

// // Predefined specializations for each skill category
// class SpecializationTemplates {
//   static const Map<String, List<Map<String, dynamic>>> templates = {
//     'health': [
//       {
//         'id': 'health_strength',
//         'name': 'Strength Training',
//         'description': 'Focus on building physical strength and muscle mass',
//         'requiredLevel': 10,
//         'bonuses': {
//           'xpMultiplier': 1.2,
//           'strengthTasks': 1.5,
//         },
//       },
//       {
//         'id': 'health_endurance',
//         'name': 'Endurance Master',
//         'description': 'Specialize in cardiovascular fitness and stamina',
//         'requiredLevel': 10,
//         'bonuses': {
//           'xpMultiplier': 1.2,
//           'cardioTasks': 1.5,
//         },
//       },
//     ],
//     'learning': [
//       {
//         'id': 'learning_technical',
//         'name': 'Technical Expert',
//         'description': 'Focus on technical and analytical skills',
//         'requiredLevel': 15,
//         'bonuses': {
//           'xpMultiplier': 1.3,
//           'technicalTasks': 1.6,
//         },
//       },
//       {
//         'id': 'learning_creative',
//         'name': 'Creative Scholar',
//         'description': 'Specialize in creative and artistic learning',
//         'requiredLevel': 15,
//         'bonuses': {
//           'xpMultiplier': 1.3,
//           'creativeTasks': 1.6,
//         },
//       },
//     ],
//     // Add more categories as needed
//   };
// } 