import 'package:flutter/material.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample achievements data
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
        'description': 'Complete at least one task every day for 7 days',
        'icon': Icons.calendar_today,
        'progress': 7,
        'target': 7,
        'unlocked': true,
      },
      {
        'title': 'Productivity Master',
        'description': 'Complete 50 tasks total',
        'icon': Icons.star,
        'progress': 42,
        'target': 50,
        'unlocked': false,
      },
      // More achievements...
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '3/10 Unlocked',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
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
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
    required this.target,
    required this.unlocked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Show achievement details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: unlocked
                      ? Colors.amber.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: unlocked ? Colors.amber : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!unlocked) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress / target,
                                backgroundColor: Colors.grey[300],
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$progress/$target',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 