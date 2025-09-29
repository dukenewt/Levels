import 'dart:developer' as dev;
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';

/// Registers a timings callback to log build/raster durations in debug/profile.
class FrameTimingsLogger {
  static final FrameTimingsLogger instance = FrameTimingsLogger._();
  FrameTimingsLogger._();

  bool _registered = false;

  void ensureRegistered({bool enabled = true}) {
    if (!kReleaseMode && enabled && !_registered) {
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
      _registered = true;
    }
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      final buildMs = t.buildDuration.inMicroseconds / 1000.0;
      final rasterMs = t.rasterDuration.inMicroseconds / 1000.0;
      dev.log(
        'frame build=${buildMs.toStringAsFixed(2)}ms raster=${rasterMs.toStringAsFixed(2)}ms',
        name: 'motion.debug',
        level: 800,
      );
    }
  }
}
