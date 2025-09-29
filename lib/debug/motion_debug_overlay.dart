import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import '../providers/settings_provider.dart';
import 'motion_debug.dart';
import 'frame_timings_logger.dart';
import 'package:provider/provider.dart';

/// Wraps the app and conditionally overlays a small dev-only motion debug panel.
class MotionDebugGate extends StatefulWidget {
  final Widget child;
  const MotionDebugGate({super.key, required this.child});

  @override
  State<MotionDebugGate> createState() => _MotionDebugGateState();
}

class _MotionDebugGateState extends State<MotionDebugGate> {
  final debug = MotionDebug.instance;

  @override
  void initState() {
    super.initState();
    // Start with normal speed
    timeDilation = 1.0;
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return widget.child;

    return AnimatedBuilder(
      animation: debug,
      builder: (context, _) {
        // Keep global timeDilation in sync
        timeDilation = debug.enabled ? debug.timeDilation : 1.0;

        // Optionally register frame timings logger
        FrameTimingsLogger.instance
            .ensureRegistered(enabled: debug.logFrameTimings);

        return Stack(
          children: [
            // Hot corner toggle: double-tap top-right to show/hide panel
            Positioned(
              right: 0,
              top: 0,
              width: 32,
              height: 32,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: () => setState(() {
                  MotionDebug.instance.toggleEnabled();
                }),
              ),
            ),
            widget.child,
            if (debug.enabled) const _DebugHandle(),
          ],
        );
      },
    );
  }
}

class _DebugHandle extends StatefulWidget {
  const _DebugHandle();
  @override
  State<_DebugHandle> createState() => _DebugHandleState();
}

class _DebugHandleState extends State<_DebugHandle> {
  Offset pos = const Offset(16, 120);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Draggable(
        feedback: _chip(theme, opacity: 0.85),
        childWhenDragging: const SizedBox.shrink(),
        onDragEnd: (d) => setState(() => pos = d.offset),
        child: GestureDetector(
          onTap: () => _openPanel(context),
          child: _chip(theme),
        ),
      ),
    );
  }

  Widget _chip(ThemeData theme, {double opacity = 1}) => Opacity(
        opacity: opacity,
        child: Chip(
          backgroundColor: theme.colorScheme.primary,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          avatar: const Icon(Icons.play_circle_outline, color: Colors.white),
          label: const Text('Motion',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      );

  Future<void> _openPanel(BuildContext context) async {
    final debug = MotionDebug.instance;
    final settings = context.read<SettingsProvider>();
    final reduced = settings.reducedMotion;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.movie_filter),
                  const SizedBox(width: 8),
                  const Text('Motion Debug',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: debug.showPerformanceOverlay,
                onChanged: (v) => setState(() {
                  MotionDebug.instance.setShowPerformanceOverlay(v);
                }),
                title: const Text('Show Performance Overlay'),
                subtitle: const Text('Flutter frame build/raster on screen'),
              ),
              SwitchListTile.adaptive(
                value: debug.showMarkers,
                onChanged: (v) => setState(() {
                  MotionDebug.instance.setShowMarkers(v);
                }),
                title: const Text('Show Markers/Paths'),
                subtitle: const Text('Draw targets, paths for diagnostics'),
              ),
              SwitchListTile.adaptive(
                value: debug.logFrameTimings,
                onChanged: (v) => setState(() {
                  MotionDebug.instance.setLogFrameTimings(v);
                }),
                title: const Text('Log Frame Timings'),
                subtitle: const Text('Build/raster durations in console'),
              ),
              const SizedBox(height: 8),
              const Text('Slow Motion'),
              Row(children: [
                for (final f in const [1.0, 0.75, 0.5, 0.25])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${(f * 100).toInt()}%'),
                      selected: debug.timeDilation == f,
                      onSelected: (_) => setState(() {
                        MotionDebug.instance.setTimeDilation(f);
                      }),
                    ),
                  ),
              ]),
              const Divider(height: 24),
              SwitchListTile.adaptive(
                value: reduced,
                onChanged: (v) async {
                  await settings.setReducedMotion(v);
                  setState(() {});
                },
                title: const Text('Reduced Motion (App Setting)'),
                subtitle: const Text('Uses accessible motion path'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
