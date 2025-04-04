import 'package:flutter/material.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final achievements = [
      {
        'title': 'Early Bird',
        'description': 'Complete 5 tasks before 9 AM',
        'icon': Icons.wb_sunny,
        'progress': 3,
        'target': 5,
        'unlocked': false,
      },
      {
        'title': 'Consistency King',
        'description': 'Complete tasks for 7 days in a row',
        'icon': Icons.calendar_today,
        'progress': 5,
        'target': 7,
        'unlocked': false,
      },
      {
        'title': 'Productivity Master',
        'description': 'Complete 50 tasks in total',
        'icon': Icons.star,
        'progress': 42,
        'target': 50,
        'unlocked': false,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${achievements.where((a) => a['unlocked'] as bool).length} of ${achievements.length} Achievements Unlocked',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return AchievementCard(
                  title: achievement['title'] as String,
                  description: achievement['description'] as String,
                  icon: achievement['icon'] as IconData,
                  progress: achievement['progress'] as int,
                  target: achievement['target'] as int,
                  unlocked: achievement['unlocked'] as bool,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AchievementCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final int progress;
  final int target;
  final bool unlocked;

  const AchievementCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
    required this.target,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: unlocked ? Colors.amber : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (!unlocked) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress / target,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$progress / $target',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 