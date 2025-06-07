// import 'package:flutter/material.dart';
// import 'coin_economy_view.dart';

// class SkillEconomyTab extends StatelessWidget {
//   final String skillId;

//   const SkillEconomyTab({
//     Key? key,
//     required this.skillId,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Skill Economy',
//             style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Earn coins by leveling up and completing achievements. Use them to purchase boosts and specializations.',
//             style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//               color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
//             ),
//           ),
//           const SizedBox(height: 24),
//           CoinEconomyView(skillId: skillId),
//         ],
//       ),
//     );
//   }
// } 