import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/skill_provider.dart';
import '../models/skill.dart';
import '../providers/coin_economy_provider.dart';

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Level: ${overallLevel.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('$coins', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: skills.length,
                itemBuilder: (context, index) {
                  final skill = skills[index];
                  final canAllocate = skill.availablePoints > 0 && _prerequisitesMet(skill, skills);
                  final coinCost = _coinCostForSkillPoint(skill);
                  final canBuy = coinProvider.hasEnoughCoins(coinCost);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(child: Text(skill.level.toString())),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(skill.name, style: Theme.of(context).textTheme.titleMedium),
                                    Text('XP: ${skill.currentXp} / ${skill.xpForNextLevel}'),
                                    Text('Available Points: ${skill.availablePoints}'),
                                    if (skill.prerequisites.isNotEmpty)
                                      Text(
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
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: canAllocate
                                    ? () => _allocatePoint(skillProvider, skill)
                                    : null,
                                child: const Text('Allocate'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.monetization_on, size: 18, color: Colors.amber),
                                label: Text('Buy Skill Point\n($coinCost)', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                                onPressed: canBuy
                                    ? () => _buySkillPoint(context, coinProvider, skillProvider, skill)
                                    : null,
                              ),
                            ],
                          ),
                        ],
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