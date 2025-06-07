// import 'dart:convert';

// enum CoinRewardType {
//   levelUp,
//   milestone,
//   balancedDevelopment,
//   crossSkillCombo,
//   dailyBonus,
//   achievement,
// }

// class CoinReward {
//   final String id;
//   final String name;
//   final String description;
//   final int amount;
//   final CoinRewardType type;
//   final DateTime timestamp;
//   final String? skillId;

//   CoinReward({
//     required this.id,
//     required this.name,
//     required this.description,
//     required this.amount,
//     required this.type,
//     required this.timestamp,
//     this.skillId,
//   });

//   // Calculate reward amount based on level
//   static int calculateLevelUpReward(int level) {
//     if (level <= 5) return 100;
//     if (level <= 10) return 200;
//     if (level <= 25) return 300;
//     if (level <= 50) return 400;
//     return 500;
//   }

//   // Calculate milestone reward
//   static int calculateMilestoneReward(int level) {
//     switch (level) {
//       case 5:
//         return 500;
//       case 10:
//         return 1000;
//       case 25:
//         return 2500;
//       case 50:
//         return 5000;
//       default:
//         return 0;
//     }
//   }

//   // Calculate balanced development reward
//   static int calculateBalancedDevelopmentReward(List<int> skillLevels) {
//     if (skillLevels.length < 2) return 0;
    
//     final maxLevel = skillLevels.reduce((a, b) => a > b ? a : b);
//     final minLevel = skillLevels.reduce((a, b) => a < b ? a : b);
    
//     if (maxLevel - minLevel <= 5) {
//       return 200 * skillLevels.length; // 200 coins per skill
//     }
//     return 0;
//   }

//   // Calculate cross-skill combo reward
//   static int calculateCrossSkillComboReward(int uniqueSkillsCompleted) {
//     if (uniqueSkillsCompleted >= 3) {
//       return 300 * uniqueSkillsCompleted; // 300 coins per unique skill
//     }
//     return 0;
//   }

//   factory CoinReward.fromJson(Map<String, dynamic> json) {
//     return CoinReward(
//       id: json['id'] as String,
//       name: json['name'] as String,
//       description: json['description'] as String,
//       amount: json['amount'] as int,
//       type: CoinRewardType.values.firstWhere(
//         (e) => e.toString() == 'CoinRewardType.${json['type']}',
//       ),
//       timestamp: DateTime.parse(json['timestamp'] as String),
//       skillId: json['skillId'] as String?,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'description': description,
//       'amount': amount,
//       'type': type.toString().split('.').last,
//       'timestamp': timestamp.toIso8601String(),
//       'skillId': skillId,
//     };
//   }
// }

// class SkillPurchase {
//   final String id;
//   final String name;
//   final String description;
//   final int cost;
//   final int durationMinutes;
//   final double xpMultiplier;
//   final DateTime? expiresAt;

//   SkillPurchase({
//     required this.id,
//     required this.name,
//     required this.description,
//     required this.cost,
//     required this.durationMinutes,
//     required this.xpMultiplier,
//     this.expiresAt,
//   });

//   factory SkillPurchase.fromJson(Map<String, dynamic> json) {
//     return SkillPurchase(
//       id: json['id'] as String,
//       name: json['name'] as String,
//       description: json['description'] as String,
//       cost: json['cost'] as int,
//       durationMinutes: json['durationMinutes'] as int,
//       xpMultiplier: (json['xpMultiplier'] as num).toDouble(),
//       expiresAt: json['expiresAt'] != null
//           ? DateTime.parse(json['expiresAt'] as String)
//           : null,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'description': description,
//       'cost': cost,
//       'durationMinutes': durationMinutes,
//       'xpMultiplier': xpMultiplier,
//       'expiresAt': expiresAt?.toIso8601String(),
//     };
//   }

//   SkillPurchase copyWith({
//     String? id,
//     String? name,
//     String? description,
//     int? cost,
//     int? durationMinutes,
//     double? xpMultiplier,
//     DateTime? expiresAt,
//   }) {
//     return SkillPurchase(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       description: description ?? this.description,
//       cost: cost ?? this.cost,
//       durationMinutes: durationMinutes ?? this.durationMinutes,
//       xpMultiplier: xpMultiplier ?? this.xpMultiplier,
//       expiresAt: expiresAt ?? this.expiresAt,
//     );
//   }
// }

// enum PurchaseType {
//   skillBooster,
//   skillTheme,
//   advancedTracking,
//   skillBadge,
// }

// // Predefined purchases for each skill
// class SkillPurchases {
//   static const Map<PurchaseType, Map<String, dynamic>> templates = {
//     PurchaseType.skillBooster: {
//       'name': 'XP Booster',
//       'description': '2x XP for 24 hours',
//       'cost': 200,
//       'effects': {
//         'xpMultiplier': 2.0,
//         'duration': 24, // hours
//       },
//     },
//     PurchaseType.skillTheme: {
//       'name': 'Custom Theme',
//       'description': 'Unique visual style for your skill tree',
//       'cost': 300,
//       'effects': {
//         'themeId': 'premium',
//       },
//     },
//     PurchaseType.advancedTracking: {
//       'name': 'Advanced Analytics',
//       'description': 'Detailed progress tracking and insights',
//       'cost': 500,
//       'effects': {
//         'analyticsEnabled': true,
//       },
//     },
//     PurchaseType.skillBadge: {
//       'name': 'Milestone Badge',
//       'description': 'Special badge for reaching skill milestones',
//       'cost': 100,
//       'effects': {
//         'badgeId': 'milestone',
//       },
//     },
//   };
// } 