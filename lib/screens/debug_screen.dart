import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/coin_economy_provider.dart';
import '../providers/skill_provider.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final skills = Provider.of<SkillProvider>(context).skills;
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Tools')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                Provider.of<CoinEconomyProvider>(context, listen: false).setTestCoins(1000);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Set coins to 1000')),
                );
              },
              child: const Text('Set 1000 Coins'),
            ),
            const SizedBox(height: 24),
            Text('Set Skill Points for a Skill:', style: Theme.of(context).textTheme.titleMedium),
            ...skills.map((skill) => ListTile(
                  title: Text(skill.name),
                  subtitle: Text('ID: ${skill.id}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Provider.of<SkillProvider>(context, listen: false).setTestSkillPoints(skill.id, 5);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Set 5 skill points for ${skill.name}')),
                      );
                    },
                    child: const Text('Set 5 Points'),
                  ),
                )),
          ],
        ),
      ),
    );
  }
} 