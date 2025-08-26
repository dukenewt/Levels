import 'dart:async';

/// Centralized animation/task orchestrator to serialize UI sequences
/// per logical entity (e.g., a task id) and avoid conflicting animations.
class AnimationOrchestrator {
  AnimationOrchestrator._();
  static final AnimationOrchestrator instance = AnimationOrchestrator._();

  final Map<String, Future<void>> _queues = {};
  bool _reducedMotion = false;

  /// Enable or disable reduced motion globally.
  void setReducedMotion(bool value) {
    _reducedMotion = value;
  }

  bool get reducedMotion => _reducedMotion;

  /// Enqueue a single async task for an entity key and run after any pending tasks.
  Future<void> run(String key, Future<void> Function() task) {
    final previous = _queues[key] ?? Future.value();
    final completer = Completer<void>();

    _queues[key] = previous.then((_) async {
      try {
        await task();
      } finally {
        // Only complete after task; do not remove from map here to preserve chaining
        completer.complete();
      }
    });

    // Cleanup once the chain settles
    _queues[key]!.whenComplete(() {
      if (_queues[key] == _queues[key]) {
        // Leave last future in place; map is cheap and avoids race.
      }
    });

    return completer.future;
  }

  /// Enqueue and run a sequence of tasks for an entity key.
  Future<void> runSequence(
      String key, List<Future<void> Function()> tasks) async {
    for (final t in tasks) {
      await run(key, t);
    }
  }
}
