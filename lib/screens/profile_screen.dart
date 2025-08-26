import 'package:cached_network_image/cached_network_image.dart';
import 'package:dailyxp/services/image_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import 'settings_screen.dart';
import 'theme_selection_screen.dart';
import 'support_screen.dart';
import 'notification_preferences_screen.dart';
import '../models/user_rank.dart';
import '../widgets/professional_progress_card.dart';
import '../widgets/talent_tree_widget.dart';
import '../widgets/perk_summary_card.dart';
import '../models/enhanced_user_perk.dart';
import '../controllers/talent_perk_controller.dart';
import '../services/architecture_integration_test.dart';
import '../config/feature_flags.dart';
import '../services/talent_trigger_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

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
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: user.profilePictureUrl != null
                      ? CachedNetworkImageProvider(user.profilePictureUrl!)
                      : null,
                  child: user.profilePictureUrl == null
                      ? Icon(Icons.person, size: 50, color: Colors.grey[600])
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: -10,
                  child: IconButton(
                    icon:
                        const Icon(Icons.camera_alt, color: Colors.blueAccent),
                    onPressed: () async {
                      final imageUploadService = ImageUploadService();
                      final String? imageUrl =
                          await imageUploadService.pickAndUploadImage(user.id);
                      if (imageUrl != null && context.mounted) {
                        await userProvider.updateProfilePicture(imageUrl);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Profile picture updated!')),
                        );
                      }
                    },
                  ),
                ),
              ],
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
                  child: _buildStatCard(
                    context,
                    'Level',
                    user.level.toString(),
                    Icons.trending_up,
                    Colors.blue,
                    subtitle: user.rank,
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

            // Talent Tree section
            TalentTreeWidget(user: user),
            const SizedBox(height: 24),

            // Active Perks section
            PerkSummaryCard(
                perks: EnhancedUserPerk.getUnlockedPerks(user.level)),
            const SizedBox(height: 32),

            // DEBUG: Architecture Integration Test (only shows in debug mode)
            _ArchitectureTestWidget(user: user),

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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile editing coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const NotificationPreferencesScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement privacy settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy settings coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.help,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help and send feedback'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupportScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Debug-only widget to test new architecture alongside existing system
class _ArchitectureTestWidget extends StatefulWidget {
  final dynamic user; // Using dynamic to avoid import issues

  const _ArchitectureTestWidget({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<_ArchitectureTestWidget> createState() =>
      _ArchitectureTestWidgetState();
}

class _ArchitectureTestWidgetState extends State<_ArchitectureTestWidget>
    with FeatureFlagMixin {
  Map<String, dynamic>? _testResults;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    if (shouldRunTests) {
      _runTest();
    }
  }

  Future<void> _runTest() async {
    if (!shouldRunTests || _isRunning) return;

    setState(() {
      _isRunning = true;
    });

    try {
      final controller =
          Provider.of<TalentPerkController>(context, listen: false);

      // Defer the test to post-frame to avoid setState during build
      final results = await Future.microtask(() async {
        return await ArchitectureIntegrationTest.runFullIntegrationTest(
          user: widget.user,
          controller: controller,
          verbose: hasLogDetailed,
        );
      });

      if (mounted) {
        setState(() {
          _testResults = results;
          _isRunning = false;
        });
      }
    } catch (e) {
      if (hasLogDetailed) {
        debugPrint('Architecture test widget error: $e');
      }
      if (mounted) {
        setState(() {
          _testResults = {
            'overall_success': false,
            'test_results': {
              'error': {'message': e.toString()}
            }
          };
          _isRunning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldRunTests) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Feature flag display
        const FeatureFlagDebugDisplay(),
        const SizedBox(height: 8),

        // Integration test results
        if (_testResults != null)
          IntegrationTestDisplay(testResults: _testResults!)
        else if (_isRunning)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              border: Border.all(color: Colors.orange, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Running architecture integration test...',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Architecture test not run',
                  style: TextStyle(fontSize: 11),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _runTest,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    'Run Test',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // Talent trigger status
        const _TalentTriggerStatusWidget(),

        const SizedBox(height: 16),
      ],
    );
  }
}

/// Debug widget to show talent trigger status
class _TalentTriggerStatusWidget extends StatelessWidget {
  const _TalentTriggerStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.shouldRunIntegrationTests()) {
      return const SizedBox.shrink();
    }

    final status = TalentTriggerService.instance.getStatus();
    final isWorking = status['is_monitoring'] == true &&
        status['has_context'] == true &&
        status['has_controller'] == true;

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isWorking
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        border: Border.all(
          color: isWorking ? Colors.green : Colors.orange,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Talent Trigger Service',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isWorking ? Colors.green : Colors.orange,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isWorking ? '✅ MONITORING' : '⚠️ NOT ACTIVE',
            style: TextStyle(
              color: isWorking ? Colors.green : Colors.orange,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          ...status.entries.where((e) => e.key != 'timestamp').map((e) => Text(
                '${e.key}: ${e.value}',
                style: const TextStyle(fontSize: 10),
              )),
        ],
      ),
    );
  }
}
