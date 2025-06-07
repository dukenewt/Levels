// MVP: Skill tree view shelved. File commented out.
/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/skill.dart';
import '../models/specialization.dart';
import '../providers/specialization_provider.dart';

class SkillTreeView extends StatelessWidget {
  final Skill skill;

  const SkillTreeView({
    Key? key,
    required this.skill,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SpecializationProvider>(
      builder: (context, specializationProvider, child) {
        final specializations = specializationProvider.getSpecializationsForCategory(skill.category);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSkillHeader(context),
            const SizedBox(height: 20),
            _buildSpecializationTree(context, specializations, specializationProvider),
          ],
        );
      },
    );
  }

  Widget _buildSkillHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                skill.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Level ${skill.level}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            skill.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: skill.levelProgress,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${skill.currentXP} / ${skill.xpForNextLevel} XP',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializationTree(
    BuildContext context,
    List<Specialization> specializations,
    SpecializationProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specializations',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...specializations.map((spec) => _buildSpecializationCard(
          context,
          spec,
          provider,
        )),
      ],
    );
  }

  Widget _buildSpecializationCard(
    BuildContext context,
    Specialization specialization,
    SpecializationProvider provider,
  ) {
    final isUnlocked = specialization.isUnlocked;
    final isActive = skill.activeSpecializationId == specialization.id;
    final canUnlock = provider.isSpecializationAvailable(skill, specialization.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  ],
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        specialization.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialization.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRequirementsList(context, specialization),
            const SizedBox(height: 16),
            _buildBonusesList(context, specialization),
            const SizedBox(height: 16),
            if (!isUnlocked && canUnlock)
              ElevatedButton(
                onPressed: () {
                  provider.unlockSpecialization(skill, specialization.id);
                },
                child: const Text('Unlock Specialization'),
              )
            else if (isUnlocked && !isActive)
              OutlinedButton(
                onPressed: () {
                  provider.activateSpecialization(skill, specialization.id);
                },
                child: const Text('Activate Specialization'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsList(
    BuildContext context,
    Specialization specialization,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requirements',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.star,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Level ${specialization.requiredLevel}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        if (specialization.prerequisites.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...specialization.prerequisites.map((prereq) => Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                prereq,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          )),
        ],
      ],
    );
  }

  Widget _buildBonusesList(
    BuildContext context,
    Specialization specialization,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonuses',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...specialization.bonuses.entries.map((bonus) => Row(
          children: [
            Icon(
              Icons.add_circle,
              size: 16,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              '${bonus.key}: ${bonus.value}x',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        )),
      ],
    );
  }
}
*/ 