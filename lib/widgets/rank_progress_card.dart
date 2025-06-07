import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/secure_user_provider.dart';
import '../models/user_rank.dart';

class RankProgressCard extends StatelessWidget {
  const RankProgressCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SecureUserProvider>(
      builder: (context, userProvider, child) {
        final currentRank = userProvider.currentRank;
        final nextRank = userProvider.nextRank;
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
                    value: userProvider.level / nextRank.requiredLevel,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(nextRank.color),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Level ${userProvider.level} / ${nextRank.requiredLevel}',
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