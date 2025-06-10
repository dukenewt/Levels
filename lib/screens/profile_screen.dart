import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/secure_user_provider.dart';
import '../widgets/rank_progress_card.dart';
import '../widgets/level_progress_card.dart';
import '../screens/task_dashboard_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/achievements_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<SecureUserProvider>(context);
    final user = userProvider.user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            CircleAvatar(
              radius: 50,
              backgroundImage: const AssetImage('assets/images/avatar.png'),
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Rank Progress Card
            const RankProgressCard(),
            const SizedBox(height: 24),

            // Level Progress Card
            Consumer<SecureUserProvider>(
              builder: (context, userProvider, child) {
                return LevelProgressCard(
                  level: userProvider.level,
                  currentXp: userProvider.currentXp,
                  nextLevelXp: userProvider.nextLevelXp,
                );
              },
            ),
            const SizedBox(height: 32),

            // Stats section
            const Text(
              'Your Stats',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Consumer<SecureUserProvider>(
                    builder: (context, userProvider, child) {
                      final currentRank = userProvider.currentRank;
                      return _buildStatCard(
                        context,
                        'Level',
                        user.level.toString(),
                        Icons.trending_up,
                        currentRank.color,
                        subtitle: currentRank.name,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'XP',
                    user.currentXp.toString(),
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Settings section
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, 
    String title, 
    String value, 
    IconData icon, 
    Color color, {
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement edit profile
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement notifications settings
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement privacy settings
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement help & support
            },
          ),
        ],
      ),
    );
  }
} 