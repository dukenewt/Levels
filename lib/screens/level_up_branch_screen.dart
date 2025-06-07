// MVP: Skill level up and branching shelved. File commented out.
/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/skill_provider.dart';
import '../models/skill.dart';
import '../providers/coin_economy_provider.dart';
import '../providers/specialization_provider.dart';
import '../models/specialization.dart';
import 'dart:math';

class LevelUpBranchScreen extends StatefulWidget {
  const LevelUpBranchScreen({Key? key}) : super(key: key);

  @override
  State<LevelUpBranchScreen> createState() => _LevelUpBranchScreenState();
}

class _LevelUpBranchScreenState extends State<LevelUpBranchScreen> {
  bool _prerequisitesMet(Skill skill, List<Skill> allSkills) {
    for (final prereq in skill.prerequisites) {
      final prereqSkill = allSkills.firstWhere(
        (s) => s.id == prereq.requiredSkillId,
        orElse: () => Skill(
          id: '',
          name: '',
          description: '',
          category: '',
          createdAt: DateTime.now(),
          lastLevelUp: DateTime.now(),
        ),
      );
      if (prereqSkill.id == '' || prereqSkill.level < prereq.requiredLevel) {
        return false;
      }
    }
    return true;
  }

  void _allocatePoint(SkillProvider skillProvider, Skill skill) async {
    // Decrement availablePoints, increment level
    final updatedSkill = skill.copyWith(
      availablePoints: skill.availablePoints - 1,
      level: skill.level + 1,
    );
    await skillProvider.updateSkill(updatedSkill);
  }

  int _coinCostForSkillPoint(Skill skill) {
    return 100 + (skill.level * 10);
  }

  Future<void> _buySkillPoint(BuildContext context, CoinEconomyProvider coinProvider, SkillProvider skillProvider, Skill skill) async {
    final cost = _coinCostForSkillPoint(skill);
    if (coinProvider.hasEnoughCoins(cost)) {
      final success = await coinProvider.spendCoins(cost);
      if (success) {
        final updatedSkill = skill.copyWith(availablePoints: skill.availablePoints + 1);
        await skillProvider.updateSkill(updatedSkill);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bought 1 skill point for ${skill.name}!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to spend coins.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final skillProvider = Provider.of<SkillProvider>(context);
    final coinProvider = Provider.of<CoinEconomyProvider>(context);
    final skills = skillProvider.skills;
    final overallLevel = skillProvider.overallLevel;
    final coins = coinProvider.coins;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Tree'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Header Row
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    Theme.of(context).colorScheme.primary.withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 28),
                  ),
                  const SizedBox(width: 18),
                  // Overall Level Badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.primary, size: 22),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Level',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    overallLevel.toStringAsFixed(1),
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Coin Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.monetization_on, color: Colors.amber[700], size: 22),
                        const SizedBox(width: 4),
                        Text(
                          '$coins',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                itemCount: skills.length,
                controller: PageController(viewportFraction: 0.85),
                itemBuilder: (context, index) {
                  final skill = skills[index];
                  final canAllocate = skill.availablePoints > 0 && _prerequisitesMet(skill, skills);
                  final coinCost = _coinCostForSkillPoint(skill);
                  final canBuy = coinProvider.hasEnoughCoins(coinCost);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              // Subtle gradient background with secondary color
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.secondary.withOpacity(0.10),
                                    Theme.of(context).colorScheme.surface,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                            child: Text(
                                              skill.level.toString(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color: Theme.of(context).colorScheme.primary,
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
                                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'XP: ${skill.currentXp} / ${skill.xpForNextLevel}',
                                                  style: Theme.of(context).textTheme.bodyMedium,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Available Points: ${skill.availablePoints}',
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                                if (skill.prerequisites.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 2.0),
                                                    child: Text(
                                                      _prerequisitesMet(skill, skills)
                                                          ? 'Prerequisites met'
                                                          : 'Prerequisites not met',
                                                      style: TextStyle(
                                                        color: _prerequisitesMet(skill, skills)
                                                            ? Colors.green
                                                            : Colors.red,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // XP Progress Bar
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: skill.xpForNextLevel > 0 ? skill.currentXp / skill.xpForNextLevel : 0.0,
                                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                                          minHeight: 10,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Action Buttons
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: canAllocate
                                                  ? () => _allocatePoint(skillProvider, skill)
                                                  : null,
                                              child: const Text('Allocate'),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              icon: const Icon(Icons.monetization_on, size: 18, color: Colors.amber),
                                              label: Text(
                                                'Buy Skill Point\n($coinCost)',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                              onPressed: canBuy
                                                  ? () => _buySkillPoint(context, coinProvider, skillProvider, skill)
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      // Perks Section
                                      PerkTreeWidget(skill: skill),
                                      // Description (optional)
                                      if (skill.description != null && skill.description.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Text(
                                          skill.description,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PerkTreeWidget extends StatelessWidget {
  final Skill skill;
  const PerkTreeWidget({Key? key, required this.skill}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SpecializationProvider>(
      builder: (context, specializationProvider, child) {
        final specializations = specializationProvider.getSpecializationsForCategory(skill.category);
        // Split into two rows for honeycomb effect
        final row1 = <Specialization>[];
        final row2 = <Specialization>[];
        for (int i = 0; i < specializations.length; i++) {
          if (i % 2 == 0) {
            row1.add(specializations[i]);
          } else {
            row2.add(specializations[i]);
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Perks', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Draw connecting lines (optional, simple for now)
                      // Row 1
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...List.generate(row1.length, (i) {
                            final spec = row1[i];
                            final isUnlocked = skill.specializations.any((s) => s.id == spec.id && s.isUnlocked);
                            final isActive = skill.activeSpecializationId == spec.id;
                            final canUnlock = specializationProvider.isSpecializationAvailable(skill, spec.id);
                            return Padding(
                              padding: const EdgeInsets.only(right: 32.0, top: 0, bottom: 8),
                              child: SizedBox(
                                width: 96,
                                height: 96,
                                child: HexagonPerkNode(
                                  spec: spec,
                                  isUnlocked: isUnlocked,
                                  isActive: isActive,
                                  canUnlock: canUnlock,
                                  onTap: () {
                                    if (!isUnlocked && canUnlock) {
                                      final updatedSkill = specializationProvider.unlockSpecialization(skill, spec.id);
                                      Provider.of<SkillProvider>(context, listen: false).updateSkill(updatedSkill);
                                    } else if (isUnlocked && !isActive) {
                                      final updatedSkill = specializationProvider.activateSpecialization(skill, spec.id);
                                      Provider.of<SkillProvider>(context, listen: false).updateSkill(updatedSkill);
                                    }
                                  },
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      // Row 2 (staggered below)
                      Positioned(
                        top: 90,
                        left: 36,
                        child: Row(
                          children: [
                            ...List.generate(row2.length, (i) {
                              final spec = row2[i];
                              final isUnlocked = skill.specializations.any((s) => s.id == spec.id && s.isUnlocked);
                              final isActive = skill.activeSpecializationId == spec.id;
                              final canUnlock = specializationProvider.isSpecializationAvailable(skill, spec.id);
                              return Padding(
                                padding: const EdgeInsets.only(right: 32.0, bottom: 8),
                                child: SizedBox(
                                  width: 96,
                                  height: 96,
                                  child: HexagonPerkNode(
                                    spec: spec,
                                    isUnlocked: isUnlocked,
                                    isActive: isActive,
                                    canUnlock: canUnlock,
                                    onTap: () {
                                      if (!isUnlocked && canUnlock) {
                                        final updatedSkill = specializationProvider.unlockSpecialization(skill, spec.id);
                                        Provider.of<SkillProvider>(context, listen: false).updateSkill(updatedSkill);
                                      } else if (isUnlocked && !isActive) {
                                        final updatedSkill = specializationProvider.activateSpecialization(skill, spec.id);
                                        Provider.of<SkillProvider>(context, listen: false).updateSkill(updatedSkill);
                                      }
                                    },
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class HexagonPerkNode extends StatelessWidget {
  final Specialization spec;
  final bool isUnlocked;
  final bool isActive;
  final bool canUnlock;
  final VoidCallback onTap;
  const HexagonPerkNode({
    Key? key,
    required this.spec,
    required this.isUnlocked,
    required this.isActive,
    required this.canUnlock,
    required this.onTap,
  }) : super(key: key);

  IconData _getIconForSpec(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('strength')) return Icons.fitness_center;
    if (lower.contains('endurance')) return Icons.directions_run;
    if (lower.contains('creativity')) return Icons.brush;
    if (lower.contains('technical')) return Icons.memory;
    if (lower.contains('focus')) return Icons.center_focus_strong;
    if (lower.contains('leadership')) return Icons.leaderboard;
    if (lower.contains('wisdom')) return Icons.psychology;
    if (lower.contains('charisma')) return Icons.record_voice_over;
    // fallback
    return Icons.star;
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color glowColor;
    double glowBlur;
    if (isActive) {
      borderColor = Colors.blueAccent;
      glowColor = Colors.blueAccent.withOpacity(0.7);
      glowBlur = 24;
    } else if (isUnlocked) {
      borderColor = Colors.green;
      glowColor = Colors.green.withOpacity(0.5);
      glowBlur = 16;
    } else if (canUnlock) {
      borderColor = Colors.amber;
      glowColor = Colors.amber.withOpacity(0.5);
      glowBlur = 12;
    } else {
      borderColor = Colors.grey;
      glowColor = Colors.transparent;
      glowBlur = 0;
    }
    final icon = _getIconForSpec(spec.name);
    return GestureDetector(
      onTap: () {
        final tooltip = '${spec.name}\n${spec.description ?? ''}';
        final snackBar = SnackBar(content: Text(tooltip));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        onTap();
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: '${spec.name}\n${spec.description ?? ''}',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Hexagon shape
                CustomPaint(
                  size: const Size(64, 64),
                  painter: _HexagonPainter(
                    borderColor: borderColor,
                    glowColor: glowColor,
                    glowBlur: glowBlur,
                    fillColor: isUnlocked ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.08),
                  ),
                ),
                Icon(icon, size: 28, color: borderColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  final Color borderColor;
  final Color glowColor;
  final double glowBlur;
  final Color fillColor;
  _HexagonPainter({required this.borderColor, required this.glowColor, required this.glowBlur, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final double w = size.width, h = size.height;
    final double side = w / 2;
    final double r = side / (2 * 0.5).abs();
    final double centerX = w / 2, centerY = h / 2;
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * 3.1415926535 / 180;
      final x = centerX + r * 0.85 * cos(angle);
      final y = centerY + r * 0.85 * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    // Glow
    if (glowBlur > 0) {
      final glowPaint = Paint()
        ..color = glowColor
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlur)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;
      canvas.drawPath(path, glowPaint);
    }
    // Fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
    // Border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
*/ 