import 'package:flutter/material.dart';
import '../models/enhanced_user_perk.dart';

class PerkSummaryCard extends StatelessWidget {
  final List<EnhancedUserPerk> perks;

  const PerkSummaryCard({
    Key? key,
    required this.perks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (perks.isEmpty) {
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
                Icons.lock_outline,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No Perks Yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
              ),
              Text(
                'Complete tasks to unlock perks',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.stars,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Active Perks (${perks.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...perks.map((perk) => _buildPerkItem(context, perk)),
          ],
        ),
      ),
    );
  }

  Widget _buildPerkItem(BuildContext context, EnhancedUserPerk perk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getPerkIcon(perk),
              color: Theme.of(context).colorScheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perk.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  perk.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: perk.effects.map((effect) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getEffectDescription(effect),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPerkIcon(EnhancedUserPerk perk) {
    // Map perk types to icons based on their primary effect
    if (perk.effects.any((e) => e.effect == PerkEffect.xpBonus)) {
      return Icons.star;
    } else if (perk.effects.any((e) => e.effect == PerkEffect.lootBoxBonus)) {
      return Icons.card_giftcard;
    } else if (perk.effects.any((e) => e.effect == PerkEffect.streakFreeze)) {
      return Icons.ac_unit;
    } else if (perk.effects.any((e) => e.effect == PerkEffect.categoryBonus)) {
      return Icons.category;
    } else {
      return Icons.auto_awesome;
    }
  }

  String _getEffectDescription(PerkEffectData effect) {
    switch (effect.effect) {
      case PerkEffect.xpBonus:
        return '+${(effect.value * 100).toInt()}% XP';
      case PerkEffect.lootBoxBonus:
        return '+${(effect.value * 100).toInt()}% Loot Box';
      case PerkEffect.streakFreeze:
        return 'Streak Protection';
      case PerkEffect.categoryBonus:
        final category = effect.category ?? 'All';
        return '+${(effect.value * 100).toInt()}% $category XP';
    }
  }
}
