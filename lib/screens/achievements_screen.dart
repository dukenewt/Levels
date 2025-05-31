import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/skill_provider.dart';
import '../models/skill_achievement.dart';
import '../models/skill.dart';
import '../providers/user_provider.dart';
import '../screens/task_dashboard_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/profile_screen.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final skillProvider = Provider.of<SkillProvider>(context);
    final allAchievements = _getAllAchievements(skillProvider);
    
    // Sort achievements by unlock date (unlocked first, then by required level)
    allAchievements.sort((a, b) {
      if (a.unlockedAt != null && b.unlockedAt != null) {
        return b.unlockedAt!.compareTo(a.unlockedAt!);
      }
      if (a.unlockedAt != null) return -1;
      if (b.unlockedAt != null) return 1;
      return a.requiredLevel.compareTo(b.requiredLevel);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${allAchievements.where((a) => a.unlockedAt != null).length}/${allAchievements.length} Unlocked',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;
          return Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primaryContainer,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).colorScheme.onPrimary,
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user?.displayName ?? 'User',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Tasks'),
                  onTap: () async {
                    debugPrint('Drawer: Tasks tapped');
                    Navigator.pop(context);
                    await Future.microtask(() {
                      if (!context.mounted) return;
                      if (ModalRoute.of(context)?.settings.name != 'TaskDashboardScreen') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TaskDashboardScreen(),
                            settings: const RouteSettings(name: 'TaskDashboardScreen'),
                          ),
                        );
                      }
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Calendar'),
                  onTap: () async {
                    debugPrint('Drawer: Calendar tapped');
                    Navigator.pop(context);
                    await Future.microtask(() {
                      if (!context.mounted) return;
                      if (ModalRoute.of(context)?.settings.name != 'CalendarScreen') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CalendarScreen(),
                            settings: const RouteSettings(name: 'CalendarScreen'),
                          ),
                        );
                      }
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart_outlined),
                  title: const Text('Stats'),
                  onTap: () async {
                    debugPrint('Drawer: Stats tapped');
                    Navigator.pop(context);
                    await Future.microtask(() {
                      if (!context.mounted) return;
                      if (ModalRoute.of(context)?.settings.name != 'StatsScreen') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StatsScreen(),
                            settings: const RouteSettings(name: 'StatsScreen'),
                          ),
                        );
                      }
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.emoji_events_outlined),
                  title: const Text('Achievements'),
                  selected: true,
                  onTap: () async {
                    debugPrint('Drawer: Achievements tapped');
                    Navigator.pop(context);
                    await Future.microtask(() {
                      if (!context.mounted) return;
                      if (ModalRoute.of(context)?.settings.name != 'AchievementsScreen') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AchievementsScreen(),
                            settings: const RouteSettings(name: 'AchievementsScreen'),
                          ),
                        );
                      }
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Profile'),
                  onTap: () async {
                    debugPrint('Drawer: Profile tapped');
                    Navigator.pop(context);
                    await Future.microtask(() {
                      if (!context.mounted) return;
                      if (ModalRoute.of(context)?.settings.name != 'ProfileScreen') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                            settings: const RouteSettings(name: 'ProfileScreen'),
                          ),
                        );
                      }
                    });
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign Out'),
                  onTap: () {
                    debugPrint('Drawer: Sign Out tapped');
                    Navigator.pop(context);
                    userProvider.signOut();
                  },
                ),
              ],
            ),
          );
        },
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allAchievements.length,
        itemBuilder: (context, index) {
          final achievement = allAchievements[index];
          final isUnlocked = achievement.unlockedAt != null;
          final isLast = index == allAchievements.length - 1;
          
          return TimelineAchievementCard(
            achievement: achievement,
            isUnlocked: isUnlocked,
            showConnector: !isLast,
          );
        },
      ),
    );
  }

  List<SkillAchievement> _getAllAchievements(SkillProvider provider) {
    final allAchievements = <SkillAchievement>[];
    for (var skill in provider.skills) {
      allAchievements.addAll(provider.getUnlockedAchievements(skill.id));
      allAchievements.addAll(provider.getLockedAchievements(skill.id));
    }
    return allAchievements;
  }
}

class TimelineAchievementCard extends StatelessWidget {
  final SkillAchievement achievement;
  final bool isUnlocked;
  final bool showConnector;

  const TimelineAchievementCard({
    Key? key,
    required this.achievement,
    required this.isUnlocked,
    required this.showConnector,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line and dot
        SizedBox(
          width: 60,
          child: Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceVariant,
                  border: Border.all(
                    color: isUnlocked
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: isUnlocked
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimary,
                      )
                    : null,
              ),
              if (showConnector)
                Container(
                  width: 2,
                  height: 100,
                  color: isUnlocked
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceVariant,
                ),
            ],
          ),
        ),
        // Achievement card
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                              : Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          achievement.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              achievement.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              achievement.description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Level ${achievement.requiredLevel}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isUnlocked && achievement.unlockedAt != null)
                        Text(
                          _formatDate(achievement.unlockedAt!),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 