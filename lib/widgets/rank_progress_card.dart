import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_rank.dart';

class RankProgressCard extends StatelessWidget {
  const RankProgressCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        if (user == null) {
          return const SizedBox.shrink();
        }

        final currentRank = UserRank.ranks.firstWhere(
            (r) => r.name == user.rank,
            orElse: () => UserRank.ranks.first);
        final nextRank = UserRank.getNextRank(user.level);
        final theme = Theme.of(context);

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: currentRank.color,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentRank.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: currentRank.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currentRank.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (nextRank != null) ...[
                  Text(
                    'Progress to ${nextRank.name}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: user.level / nextRank.requiredLevel,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(nextRank.color),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Level ${user.level} / ${nextRank.requiredLevel}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ] else ...[
                  Text(
                    'Maximum Rank Achieved!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: currentRank.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
