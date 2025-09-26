import 'dart:async';
import 'package:flutter/material.dart';

/// Centralized animation/task orchestrator to serialize UI sequences
/// per logical entity (e.g., a task id) and avoid conflicting animations.
/// Enhanced with controller lifecycle management and gaming-level polish.
class AnimationOrchestrator {
  AnimationOrchestrator._();
  static final AnimationOrchestrator instance = AnimationOrchestrator._();

  final Map<String, Future<void>> _queues = {};
  final Map<String, AnimationController> _controllerPool = {};
  final Map<String, List<AnimationController>> _namedControllers = {};
  bool _reducedMotion = false;

  /// Enable or disable reduced motion globally.
  void setReducedMotion(bool value) {
    _reducedMotion = value;
    // Update all existing controllers
    for (final controller in _controllerPool.values) {
      _updateControllerForReducedMotion(controller);
    }
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

  /// Get or create a controller with automatic lifecycle management
  AnimationController getController(
    String key,
    TickerProvider vsync, {
    required Duration duration,
    Duration? reverseDuration,
    String? debugLabel,
    double? lowerBound,
    double? upperBound,
    AnimationBehavior? animationBehavior,
  }) {
    final controllerId = '${key}_${duration.inMilliseconds}';

    if (_controllerPool.containsKey(controllerId)) {
      return _controllerPool[controllerId]!;
    }

    final adjustedDuration = _reducedMotion
        ? Duration(milliseconds: (duration.inMilliseconds * 0.3).round())
        : duration;

    final controller = AnimationController(
      duration: adjustedDuration,
      reverseDuration: reverseDuration,
      debugLabel: debugLabel ?? key,
      lowerBound: lowerBound ?? 0.0,
      upperBound: upperBound ?? 1.0,
      animationBehavior: animationBehavior ?? AnimationBehavior.normal,
      vsync: vsync,
    );

    _controllerPool[controllerId] = controller;

    // Add to named group for easier management
    _namedControllers.putIfAbsent(key, () => []).add(controller);

    return controller;
  }

  /// Get multiple controllers for complex animations
  List<AnimationController> getControllers(
    String groupKey,
    TickerProvider vsync,
    List<AnimationSpec> specs,
  ) {
    return specs
        .map((spec) => getController(
              '${groupKey}_${spec.name}',
              vsync,
              duration: spec.duration,
              reverseDuration: spec.reverseDuration,
              debugLabel: '${groupKey}_${spec.name}',
            ))
        .toList();
  }

  /// Create animation with automatic curve and timing
  Animation<T> createAnimation<T>(
    AnimationController controller,
    Tween<T> tween, {
    Curve? curve,
    double? begin,
    double? end,
  }) {
    final adjustedCurve =
        _reducedMotion ? Curves.linear : (curve ?? Curves.easeInOut);

    return tween.animate(CurvedAnimation(
      parent: controller,
      curve: Interval(begin ?? 0.0, end ?? 1.0, curve: adjustedCurve),
    ));
  }

  /// Run a choreographed animation sequence
  Future<void> runChoreography(
    String key,
    List<AnimationStep> steps, {
    bool allowConcurrent = false,
  }) async {
    if (!allowConcurrent && _queues.containsKey(key)) {
      await _queues[key];
    }

    final completer = Completer<void>();
    _queues[key] = completer.future;

    try {
      for (final step in steps) {
        if (_reducedMotion && step.skipOnReducedMotion) {
          continue;
        }

        switch (step.type) {
          case AnimationStepType.forward:
            await step.controller?.forward();
            break;
          case AnimationStepType.reverse:
            await step.controller?.reverse();
            break;
          case AnimationStepType.reset:
            step.controller?.reset();
            break;
          case AnimationStepType.stop:
            step.controller?.stop();
            break;
          case AnimationStepType.delay:
            await Future.delayed(step.duration ?? Duration.zero);
            break;
          case AnimationStepType.parallel:
            final futures = step.controllers?.map((c) => c.forward()) ?? [];
            await Future.wait(futures);
            break;
          case AnimationStepType.custom:
            if (step.customAction != null) {
              await step.customAction!();
            }
            break;
        }

        if (step.delay != null && !_reducedMotion) {
          await Future.delayed(step.delay!);
        }
      }
    } finally {
      completer.complete();
      _queues.remove(key);
    }
  }

  /// Dispose controllers by group or key
  void disposeControllers(String keyOrGroup) {
    // Dispose by exact key
    if (_controllerPool.containsKey(keyOrGroup)) {
      _controllerPool[keyOrGroup]?.dispose();
      _controllerPool.remove(keyOrGroup);
    }

    // Dispose by group
    if (_namedControllers.containsKey(keyOrGroup)) {
      for (final controller in _namedControllers[keyOrGroup]!) {
        controller.dispose();
        _controllerPool.removeWhere((key, value) => value == controller);
      }
      _namedControllers.remove(keyOrGroup);
    }
  }

  /// Dispose all controllers
  void disposeAll() {
    for (final controller in _controllerPool.values) {
      controller.dispose();
    }
    _controllerPool.clear();
    _namedControllers.clear();
  }

  /// Update controller for reduced motion
  void _updateControllerForReducedMotion(AnimationController controller) {
    if (_reducedMotion) {
      controller.duration = Duration(
          milliseconds: (controller.duration!.inMilliseconds * 0.3).round());
    }
  }

  /// Preset animation sequences for common UI patterns
  static List<AnimationStep> get fadeInSequence => [
        AnimationStep.forward('fadeIn'),
      ];

  static List<AnimationStep> get scaleInSequence => [
        AnimationStep.forward('scaleIn'),
      ];

  static List<AnimationStep> get slideUpSequence => [
        AnimationStep.forward('slideUp'),
      ];

  static List<AnimationStep> get celebrationSequence => [
        AnimationStep.parallel(['scale', 'glow', 'particles']),
        AnimationStep.wait(Duration(milliseconds: 500)),
        AnimationStep.forward('fadeOut'),
      ];

  static List<AnimationStep> get taskCompletionSequence => [
        AnimationStep.forward('checkmark'),
        AnimationStep.wait(Duration(milliseconds: 200)),
        AnimationStep.parallel(['xpGain', 'progressRing']),
        AnimationStep.wait(Duration(milliseconds: 300)),
        AnimationStep.forward('celebration'),
      ];
}

/// Specification for animation controller creation
class AnimationSpec {
  final String name;
  final Duration duration;
  final Duration? reverseDuration;
  final Curve? curve;

  const AnimationSpec({
    required this.name,
    required this.duration,
    this.reverseDuration,
    this.curve,
  });

  // Common animation specs
  static const quick = AnimationSpec(
    name: 'quick',
    duration: Duration(milliseconds: 200),
  );

  static const medium = AnimationSpec(
    name: 'medium',
    duration: Duration(milliseconds: 500),
  );

  static const slow = AnimationSpec(
    name: 'slow',
    duration: Duration(milliseconds: 800),
  );

  static const bounce = AnimationSpec(
    name: 'bounce',
    duration: Duration(milliseconds: 600),
    curve: Curves.elasticOut,
  );

  static const celebration = AnimationSpec(
    name: 'celebration',
    duration: Duration(milliseconds: 1200),
    curve: Curves.easeOutBack,
  );
}

/// Step in an animation sequence
class AnimationStep {
  final AnimationStepType type;
  final AnimationController? controller;
  final List<AnimationController>? controllers;
  final Duration? duration;
  final Duration? delay;
  final bool skipOnReducedMotion;
  final Future<void> Function()? customAction;

  const AnimationStep({
    required this.type,
    this.controller,
    this.controllers,
    this.duration,
    this.delay,
    this.skipOnReducedMotion = false,
    this.customAction,
  });

  static AnimationStep forward(String controllerId) => AnimationStep(
        type: AnimationStepType.forward,
        controller:
            AnimationOrchestrator.instance._controllerPool[controllerId],
      );

  static AnimationStep reverse(String controllerId) => AnimationStep(
        type: AnimationStepType.reverse,
        controller:
            AnimationOrchestrator.instance._controllerPool[controllerId],
      );

  static AnimationStep parallel(List<String> controllerIds) => AnimationStep(
        type: AnimationStepType.parallel,
        controllers: controllerIds
            .map((id) => AnimationOrchestrator.instance._controllerPool[id])
            .where((c) => c != null)
            .cast<AnimationController>()
            .toList(),
      );

  static AnimationStep wait(Duration duration) => AnimationStep(
        type: AnimationStepType.delay,
        duration: duration,
      );

  static AnimationStep custom(Future<void> Function() action) => AnimationStep(
        type: AnimationStepType.custom,
        customAction: action,
      );
}

enum AnimationStepType {
  forward,
  reverse,
  reset,
  stop,
  delay,
  parallel,
  custom,
}

/// Mixin for widgets that need orchestrated animations
mixin OrchestrationMixin<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  final _orchestrator = AnimationOrchestrator.instance;
  late final String _animationKey;

  @override
  void initState() {
    super.initState();
    _animationKey = '${widget.runtimeType}_$hashCode';
  }

  /// Get a managed controller
  AnimationController getAnimationController(
    String name, {
    required Duration duration,
    Duration? reverseDuration,
  }) {
    return _orchestrator.getController(
      '${_animationKey}_$name',
      this,
      duration: duration,
      reverseDuration: reverseDuration,
    );
  }

  /// Get multiple controllers
  List<AnimationController> getAnimationControllers(List<AnimationSpec> specs) {
    return _orchestrator.getControllers(_animationKey, this, specs);
  }

  /// Create an animation from controller
  Animation<V> createAnimation<V>(
    AnimationController controller,
    Tween<V> tween, {
    Curve? curve,
  }) {
    return _orchestrator.createAnimation(controller, tween, curve: curve);
  }

  /// Run a choreographed sequence
  Future<void> runAnimationSequence(
    String name,
    List<AnimationStep> steps, {
    bool allowConcurrent = false,
  }) {
    return _orchestrator.runChoreography(
      '${_animationKey}_$name',
      steps,
      allowConcurrent: allowConcurrent,
    );
  }

  @override
  void dispose() {
    _orchestrator.disposeControllers(_animationKey);
    super.dispose();
  }
}
