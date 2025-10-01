import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/epic_provider.dart';
import '../providers/theme_provider.dart';
import '../models/theme_model.dart';
import 'theme_selection_screen.dart';
import '../core/animation/animation_orchestrator.dart';
import '../providers/user_provider.dart';
import '../providers/task_provider.dart';
import '../models/epic_project.dart';
import '../models/task.dart';
import '../widgets/epic_creation_dialog.dart';
import '../widgets/epic_progress_card.dart';

class EpicProjectScreen extends StatefulWidget {
  const EpicProjectScreen({Key? key}) : super(key: key);

  @override
  State<EpicProjectScreen> createState() => _EpicProjectScreenState();
}

class _EpicProjectScreenState extends State<EpicProjectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    final epicProvider = Provider.of<EpicProvider>(context, listen: false);
    if (!epicProvider.isInitialized) {
      await epicProvider.initialize();
    }
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Epic Projects'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.rocket_launch), text: 'Active'),
            Tab(icon: Icon(Icons.assignment), text: 'Planning'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Completed'),
          ],
        ),
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Consumer3<EpicProvider, UserProvider, TaskProvider>(
              builder:
                  (context, epicProvider, userProvider, taskProvider, child) {
                final user = userProvider.user;

                if (user == null) {
                  return const Center(
                    child: Text('Please log in to view epic projects'),
                  );
                }

                // Check if user has Project Management talent
                if (!user.hasProjectManagementTalent()) {
                  return _buildNoTalentView();
                }

                final userEpics = epicProvider.getEpicsForUser(user.id);

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEpicList(userEpics.where((e) => e.isActive).toList(),
                        taskProvider),
                    _buildEpicList(
                        userEpics
                            .where((e) => e.status == EpicStatus.planning)
                            .toList(),
                        taskProvider),
                    _buildEpicList(
                        userEpics.where((e) => e.isCompleted).toList(),
                        taskProvider),
                  ],
                );
              },
            ),
      floatingActionButton: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;
          if (user?.hasProjectManagementTalent() != true) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () => _showCreateEpicDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Epic'),
          );
        },
      ),
    );
  }

  Widget _buildNoTalentView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Epic Projects Locked',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Epic Projects require the Project Management talent. '
              'Reach level 5, 10, 15, 20, or 25 to unlock talent choices!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Epic Projects let you create multi-task collections '
                    'with special rewards like exclusive themes!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpicList(List<EpicProject> epics, TaskProvider taskProvider) {
    if (epics.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<EpicProvider>(context, listen: false).initialize();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: epics.length,
        itemBuilder: (context, index) {
          final epic = epics[index];
          final tasks = epic.taskIds
              .map((id) => taskProvider.getTaskById(id))
              .where((task) => task != null)
              .cast<Task>()
              .toList();

          return EpicProgressCard(
            epic: epic,
            tasks: tasks,
            onTap: () => _showEpicDetails(context, epic),
            onStart: epic.canStart ? () => _startEpic(epic) : null,
            onComplete: epic.isActive && epic.progressPercentage >= 1.0
                ? () => _completeEpic(epic)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rocket_launch_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Epic Projects Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Create your first epic project to unlock exclusive rewards!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateEpicDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const EpicCreationDialog(),
    );
  }

  void _showEpicDetails(BuildContext context, EpicProject epic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEpicDetailsSheet(epic),
    );
  }

  Widget _buildEpicDetailsSheet(EpicProject epic) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            epic.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (epic.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              epic.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _buildStatusBadge(epic.status),
                  ],
                ),
              ),

              // Progress indicator
              if (epic.isActive) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${epic.completedTasks}/${epic.requiredTasks}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: epic.progressPercentage,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceVariant,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Reward preview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reward: ${epic.reward.name}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              epic.reward.description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tasks list (live)
              Expanded(
                child: Consumer<TaskProvider>(
                  builder: (context, taskProvider, _) {
                    final freshTasks = epic.taskIds
                        .map((id) => taskProvider.getTaskById(id))
                        .where((t) => t != null)
                        .cast<Task>()
                        .toList();
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: freshTasks.length + 1, // +1 for header
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Tasks (${freshTasks.length})',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          );
                        }
                        final task = freshTasks[index - 1];
                        final canComplete = !task.isCompleted;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              task.isCompleted
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: task.isCompleted
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5),
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: task.description.isNotEmpty
                                ? Text(task.description)
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildDifficultyBadge(task.difficulty),
                                if (canComplete) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'Mark complete',
                                    icon:
                                        const Icon(Icons.check_circle_outline),
                                    onPressed: () =>
                                        _completeTaskFromSheet(context, task),
                                  ),
                                ],
                              ],
                            ),
                            onTap: canComplete
                                ? () => _completeTaskFromSheet(context, task)
                                : null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _completeTaskFromSheet(BuildContext context, Task task) {
    // Defer completion to next frame to avoid notify/build re-entrancy
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Provider.of<TaskProvider>(context, listen: false)
          .completeTask(context, task);
    });
  }

  Widget _buildStatusBadge(EpicStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case EpicStatus.planning:
        color = Colors.orange;
        icon = Icons.edit;
        break;
      case EpicStatus.active:
        color = Colors.blue;
        icon = Icons.play_arrow;
        break;
      case EpicStatus.completed:
        color = Colors.green;
        icon = Icons.check;
        break;
      case EpicStatus.abandoned:
        color = Colors.red;
        icon = Icons.close;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(TaskDifficulty difficulty) {
    Color color;
    switch (difficulty) {
      case TaskDifficulty.easy:
        color = Colors.green;
        break;
      case TaskDifficulty.medium:
        color = Colors.orange;
        break;
      case TaskDifficulty.hard:
        color = Colors.red;
        break;
      case TaskDifficulty.epic:
        color = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        difficulty.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Future<void> _startEpic(EpicProject epic) async {
    final epicProvider = Provider.of<EpicProvider>(context, listen: false);
    final success = await epicProvider.startEpic(epic.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${epic.title} has been started!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _completeEpic(EpicProject epic) async {
    final epicProvider = Provider.of<EpicProvider>(context, listen: false);
    final success = await epicProvider.completeEpic(epic.id);

    if (success && mounted) {
      // Try to unlock theme reward if present
      ThemeType? unlockedTheme;
      try {
        if (epic.reward.type == EpicRewardType.theme) {
          switch (epic.reward.id) {
            case 'ocean_theme':
              unlockedTheme = ThemeType.oceanDepths;
              break;
            case 'forest_theme':
              unlockedTheme = ThemeType.forestCanopy;
              break;
            case 'sunset_theme':
              unlockedTheme = ThemeType.sunsetGlow;
              break;
          }
          if (unlockedTheme != null) {
            final themeProvider =
                Provider.of<ThemeProvider>(context, listen: false);
            await themeProvider.unlockPremiumTheme(unlockedTheme);
          }
        }
      } catch (_) {}

      _showEpicCompletionCelebration(epic, unlockedTheme: unlockedTheme);
    }
  }

  void _showEpicCompletionCelebration(EpicProject epic,
      {ThemeType? unlockedTheme}) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final surface = theme.colorScheme.surface;
        final onSurface = theme.colorScheme.onSurface;
        final rewardTheme = unlockedTheme != null
            ? AppTheme.getThemeByType(unlockedTheme)
            : null;
        final reduced = AnimationOrchestrator.instance.reducedMotion;
        return SafeArea(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.95, end: 1.0),
            duration: reduced
                ? const Duration(milliseconds: 120)
                : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            builder: (context, scale, child) {
              return Opacity(
                opacity: ((scale - 0.95) / 0.05).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: onSurface.withOpacity(0.08)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events,
                          color: Colors.amber, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Epic Completed',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You finished "${epic.title}" — nice work!\nReward unlocked:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        if (rewardTheme != null)
                          _ThemePreviewChip(appTheme: rewardTheme)
                        else
                          const Icon(Icons.card_giftcard, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                epic.reward.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                epic.reward.description,
                                style: theme.textTheme.bodySmall,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Later'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const ThemeSelectionScreen()),
                            );
                          },
                          icon: const Icon(Icons.palette_outlined),
                          label: const Text('Manage Themes'),
                        ),
                      ),
                      if (unlockedTheme != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final themeProvider = Provider.of<ThemeProvider>(
                                  context,
                                  listen: false);
                              try {
                                await themeProvider.setTheme(unlockedTheme!);
                                if (context.mounted)
                                  Navigator.of(context).pop();
                              } catch (_) {
                                if (context.mounted)
                                  Navigator.of(context).pop();
                              }
                            },
                            icon: const Icon(Icons.color_lens),
                            label: const Text('Apply Theme'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ThemePreviewChip extends StatelessWidget {
  final AppTheme appTheme;
  const _ThemePreviewChip({required this.appTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: appTheme.gradientColors),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}
