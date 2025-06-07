// // Remove all code that uses Skill and related UI for skill progress card.

// import 'package:flutter/material.dart';
// import '../models/skill.dart';
// import 'animated_xp_bar.dart';

// class SkillProgressCard extends StatelessWidget {
//   final Skill skill;

//   const SkillProgressCard({
//     Key? key,
//     required this.skill,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
    
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: skill.color.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(
//                     IconData(
//                       int.parse(skill.icon),
//                       fontFamily: 'MaterialIcons',
//                     ),
//                     color: skill.color,
//                     size: 24,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         skill.name,
//                         style: theme.textTheme.titleMedium?.copyWith(
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Text(
//                         'Level ${skill.level}',
//                         style: theme.textTheme.bodyMedium?.copyWith(
//                           color: theme.textTheme.bodySmall?.color,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 6,
//                   ),
//                   decoration: BoxDecoration(
//                     color: skill.color.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     '${skill.currentXp}/${skill.xpToNextLevel} XP',
//                     style: TextStyle(
//                       color: skill.color,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             AnimatedXPBar(
//               progress: skill.progressPercentage / 100,
//               color: skill.color,
//               height: 8,
//               animationType: AnimationType.pulse,
//               duration: const Duration(milliseconds: 1000),
//             ),
//             const SizedBox(height: 8),
//           ],
//         ),
//       ),
//     );
//   }
// } 