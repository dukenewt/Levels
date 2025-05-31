import 'package:flutter/material.dart';

class LevelUpOverlay extends StatelessWidget {
  final int newLevel;
  final VoidCallback onDismiss;

  const LevelUpOverlay({
    Key? key,
    required this.newLevel,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events,
                size: 64,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              Text(
                'Level Up!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'You reached level $newLevel!',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onDismiss,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 