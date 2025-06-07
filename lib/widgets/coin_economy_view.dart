// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../models/coin_economy.dart';
// import '../providers/coin_economy_provider.dart';

// class CoinEconomyView extends StatelessWidget {
//   final String skillId;

//   const CoinEconomyView({
//     Key? key,
//     required this.skillId,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<CoinEconomyProvider>(
//       builder: (context, provider, child) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildCoinBalance(context, provider),
//             const SizedBox(height: 24),
//             _buildAvailablePurchases(context, provider),
//             const SizedBox(height: 24),
//             _buildActivePurchases(context, provider),
//             const SizedBox(height: 24),
//             _buildRecentRewards(context, provider),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildCoinBalance(BuildContext context, CoinEconomyProvider provider) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surface,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Icon(
//             Icons.monetization_on,
//             size: 32,
//             color: Theme.of(context).colorScheme.primary,
//           ),
//           const SizedBox(width: 16),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Coin Balance',
//                 style: Theme.of(context).textTheme.titleMedium,
//               ),
//               Text(
//                 provider.coins.toString(),
//                 style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAvailablePurchases(
//     BuildContext context,
//     CoinEconomyProvider provider,
//   ) {
//     final purchases = provider.getAvailablePurchases(skillId);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Available Purchases',
//           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),
//         ...purchases.map((purchase) => _buildPurchaseCard(
//           context,
//           purchase,
//           provider,
//         )),
//       ],
//     );
//   }

//   Widget _buildActivePurchases(
//     BuildContext context,
//     CoinEconomyProvider provider,
//   ) {
//     final activePurchases = provider.getActivePurchases(skillId);

//     if (activePurchases.isEmpty) return const SizedBox.shrink();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Active Purchases',
//           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),
//         ...activePurchases.map((purchase) => _buildActivePurchaseCard(
//           context,
//           purchase,
//         )),
//       ],
//     );
//   }

//   Widget _buildRecentRewards(
//     BuildContext context,
//     CoinEconomyProvider provider,
//   ) {
//     final recentRewards = provider.rewards
//         .where((r) => r.type != CoinRewardType.dailyBonus)
//         .take(5)
//         .toList();

//     if (recentRewards.isEmpty) return const SizedBox.shrink();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Recent Rewards',
//           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),
//         ...recentRewards.map((reward) => _buildRewardCard(
//           context,
//           reward,
//         )),
//       ],
//     );
//   }

//   Widget _buildPurchaseCard(
//     BuildContext context,
//     SkillPurchase purchase,
//     CoinEconomyProvider provider,
//   ) {
//     final canAfford = provider.hasEnoughCoins(purchase.cost);

//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         purchase.name,
//                         style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         purchase.description,
//                         style: Theme.of(context).textTheme.bodyMedium,
//                       ),
//                     ],
//                   ),
//                 ),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.monetization_on,
//                           size: 16,
//                           color: Theme.of(context).colorScheme.primary,
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           purchase.cost.toString(),
//                           style: TextStyle(
//                             color: canAfford
//                                 ? Theme.of(context).colorScheme.primary
//                                 : Theme.of(context).colorScheme.error,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     ElevatedButton(
//                       onPressed: canAfford
//                           ? () => provider.purchaseItem(skillId, purchase.id)
//                           : null,
//                       child: const Text('Purchase'),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActivePurchaseCard(
//     BuildContext context,
//     SkillPurchase purchase,
//   ) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(12),
//           gradient: LinearGradient(
//             colors: [
//               Theme.of(context).colorScheme.primary.withOpacity(0.1),
//               Theme.of(context).colorScheme.primary.withOpacity(0.05),
//             ],
//           ),
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     purchase.name,
//                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     purchase.description,
//                     style: Theme.of(context).textTheme.bodyMedium,
//                   ),
//                   if (purchase.expiresAt != null) ...[
//                     const SizedBox(height: 8),
//                     Text(
//                       'Expires in ${_formatTimeRemaining(purchase.expiresAt!)}',
//                       style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         color: Theme.of(context).colorScheme.primary,
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 8,
//                 vertical: 4,
//               ),
//               decoration: BoxDecoration(
//                 color: Theme.of(context).colorScheme.primary,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Text(
//                 'Active',
//                 style: TextStyle(
//                   color: Theme.of(context).colorScheme.onPrimary,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRewardCard(
//     BuildContext context,
//     CoinReward reward,
//   ) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Icon(
//               _getRewardIcon(reward.type),
//               size: 24,
//               color: Theme.of(context).colorScheme.primary,
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     reward.name,
//                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     reward.description,
//                     style: Theme.of(context).textTheme.bodyMedium,
//                   ),
//                 ],
//               ),
//             ),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.monetization_on,
//                       size: 16,
//                       color: Theme.of(context).colorScheme.primary,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       '+${reward.amount}',
//                       style: TextStyle(
//                         color: Theme.of(context).colorScheme.primary,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   IconData _getRewardIcon(CoinRewardType type) {
//     switch (type) {
//       case CoinRewardType.levelUp:
//         return Icons.trending_up;
//       case CoinRewardType.milestone:
//         return Icons.emoji_events;
//       case CoinRewardType.balancedDevelopment:
//         return Icons.balance;
//       case CoinRewardType.crossSkillCombo:
//         return Icons.link;
//       case CoinRewardType.dailyBonus:
//         return Icons.calendar_today;
//       case CoinRewardType.achievement:
//         return Icons.star;
//     }
//   }

//   String _formatTimeRemaining(DateTime expiresAt) {
//     final now = DateTime.now();
//     final difference = expiresAt.difference(now);
    
//     if (difference.inHours > 0) {
//       return '${difference.inHours}h ${difference.inMinutes % 60}m';
//     } else {
//       return '${difference.inMinutes}m';
//     }
//   }
// } 