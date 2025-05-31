import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/skill.dart';
import '../models/skill_achievement.dart';
import '../providers/skill_provider.dart';

class SkillProgressionScreen extends StatefulWidget {
  const SkillProgressionScreen({Key? key}) : super(key: key);

  @override
  State<SkillProgressionScreen> createState() => _SkillProgressionScreenState();
}

class _SkillProgressionScreenState extends State<SkillProgressionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'health';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildSkillCard(Skill skill) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    skill.level.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        skill.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: skill.levelProgress,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${skill.currentXP}/${skill.xpForNextLevel} XP',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Total: ${skill.totalXP} XP',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsList(Skill skill) {
    final skillProvider = Provider.of<SkillProvider>(context);
    final unlockedAchievements = skillProvider.getUnlockedAchievements(skill.id);
    final lockedAchievements = skillProvider.getLockedAchievements(skill.id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (unlockedAchievements.isNotEmpty) ...[
          Text(
            'Unlocked Achievements',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...unlockedAchievements.map((achievement) => _buildAchievementCard(achievement, true)),
          const SizedBox(height: 24),
        ],
        if (lockedAchievements.isNotEmpty) ...[
          Text(
            'Locked Achievements',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...lockedAchievements.map((achievement) => _buildAchievementCard(achievement, false)),
        ],
      ],
    );
  }

  Widget _buildAchievementCard(SkillAchievement achievement, bool isUnlocked) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUnlocked
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          child: Text(
            achievement.icon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(achievement.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            const SizedBox(height: 4),
            Text(
              'Required Level: ${achievement.requiredLevel}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (isUnlocked && achievement.unlockedAt != null)
              Text(
                'Unlocked: ${achievement.unlockedAt!.toString().split('.')[0]}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: isUnlocked
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.lock, color: Colors.grey),
      ),
    );
  }

  Widget _buildSkillTree(Skill skill) {
    final skillProvider = Provider.of<SkillProvider>(context);
    final progress = skillProvider.getSkillTreeProgress(skill.id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSkillTreeNode(
          'Novice',
          'Level 1-9',
          progress['novice']['isUnlocked'],
          progress['novice']['isCompleted'],
          progress['novice']['progress'],
        ),
        _buildSkillTreeConnector(progress['novice']['isCompleted']),
        _buildSkillTreeNode(
          'Apprentice',
          'Level 10-24',
          progress['apprentice']['isUnlocked'],
          progress['apprentice']['isCompleted'],
          progress['apprentice']['progress'],
        ),
        _buildSkillTreeConnector(progress['apprentice']['isCompleted']),
        _buildSkillTreeNode(
          'Expert',
          'Level 25-49',
          progress['expert']['isUnlocked'],
          progress['expert']['isCompleted'],
          progress['expert']['progress'],
        ),
        _buildSkillTreeConnector(progress['expert']['isCompleted']),
        _buildSkillTreeNode(
          'Master',
          'Level 50+',
          progress['master']['isUnlocked'],
          progress['master']['isCompleted'],
          progress['master']['progress'],
        ),
      ],
    );
  }

  Widget _buildSkillTreeNode(
    String title,
    String description,
    bool isUnlocked,
    bool isCompleted,
    double progress,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCompleted
                      ? Icons.check_circle
                      : isUnlocked
                          ? Icons.lock_open
                          : Icons.lock,
                  color: isCompleted
                      ? Colors.green
                      : isUnlocked
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isUnlocked && !isCompleted) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                minHeight: 4,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkillTreeConnector(bool isCompleted) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      height: 24,
      child: Center(
        child: Container(
          width: 2,
          color: isCompleted
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skillProvider = Provider.of<SkillProvider>(context);
    final skill = skillProvider.getSkillById(_selectedCategory);

    if (skill == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Progression'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Achievements'),
            Tab(text: 'Skill Tree'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Select Skill',
                border: OutlineInputBorder(),
              ),
              items: SkillCategories.categories.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSkillCard(skill),
                _buildAchievementsList(skill),
                _buildSkillTree(skill),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 