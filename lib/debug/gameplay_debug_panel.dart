import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../gameplay/game_balance.dart';

/// Shows a bottom sheet with gameplay tuning sliders (debug only).
Future<void> showGameplayDebugPanel(BuildContext context) async {
  if (!kDebugMode) return;
  final gb = GameBalance.instance;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return _GameplayDebugSheet(gb: gb);
    },
  );
}

class _GameplayDebugSheet extends StatefulWidget {
  final GameBalance gb;
  const _GameplayDebugSheet({required this.gb});

  @override
  State<_GameplayDebugSheet> createState() => _GameplayDebugSheetState();
}

class _GameplayDebugSheetState extends State<_GameplayDebugSheet> {
  late GameBalance gb;

  @override
  void initState() {
    super.initState();
    gb = widget.gb;
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    int fractionDigits = 2,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(
              value.toStringAsFixed(fractionDigits),
              textAlign: TextAlign.right,
              overflow: TextOverflow.fade,
              maxLines: 1,
            ),
          ),
        ]),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: (v) => setState(() {
            onChanged(v);
            gb.notifyListeners();
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: media.viewInsets.bottom + 12,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (split into two rows to avoid overflow)
              Row(children: const [
                Icon(Icons.tune),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gameplay Debug',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() => gb.applyFastLevelingPreset());
                    },
                    child: const Text('Fast Leveling'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      setState(() => gb.resetDefaults());
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Base formula
              const Text('Base XP Formula',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              _slider(
                label: 'A (sqrt coeff)',
                value: gb.baseA,
                min: 0,
                max: 30,
                onChanged: (v) => gb.baseA = v,
              ),
              _slider(
                label: 'B (base offset)',
                value: gb.baseB,
                min: 0,
                max: 20,
                onChanged: (v) => gb.baseB = v,
              ),
              Row(children: [
                const Expanded(
                    child: Text('Min Base XP Floor',
                        overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 12),
                Flexible(
                  child: DropdownButton<int>(
                    value: gb.minBaseXPFloor,
                    items: const [5, 8, 10, 12, 15]
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text('$e')))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => gb.minBaseXPFloor = v ?? 5),
                  ),
                ),
              ]),
              const Divider(height: 24),
              // Difficulty multipliers
              const Text('Difficulty Multipliers',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              _slider(
                label: 'Easy',
                value: gb.diffEasy,
                min: 0.5,
                max: 1.5,
                onChanged: (v) => gb.diffEasy = v,
              ),
              _slider(
                label: 'Medium',
                value: gb.diffMedium,
                min: 0.8,
                max: 1.5,
                onChanged: (v) => gb.diffMedium = v,
              ),
              _slider(
                label: 'Hard',
                value: gb.diffHard,
                min: 1.0,
                max: 2.5,
                onChanged: (v) => gb.diffHard = v,
              ),
              _slider(
                label: 'Epic',
                value: gb.diffEpic,
                min: 1.5,
                max: 3.5,
                onChanged: (v) => gb.diffEpic = v,
              ),
              const Divider(height: 24),
              // Morning & Streak
              const Text('Bonuses',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              _slider(
                label: 'Morning Bonus %',
                value: gb.morningBonusPct,
                min: 0.0,
                max: 0.3,
                onChanged: (v) => gb.morningBonusPct = v,
              ),
              _slider(
                label: 'Streak Base % of Base XP',
                value: gb.streakBasePct,
                min: 0.0,
                max: 0.2,
                onChanged: (v) => gb.streakBasePct = v,
              ),
              const Divider(height: 24),
              const Text('Loot Box',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              _slider(
                label: 'Chance Easy',
                value: gb.lootEasy,
                min: 0.0,
                max: 0.5,
                onChanged: (v) => gb.lootEasy = v,
              ),
              _slider(
                label: 'Chance Medium',
                value: gb.lootMedium,
                min: 0.0,
                max: 0.5,
                onChanged: (v) => gb.lootMedium = v,
              ),
              _slider(
                label: 'Chance Hard',
                value: gb.lootHard,
                min: 0.0,
                max: 0.5,
                onChanged: (v) => gb.lootHard = v,
              ),
              _slider(
                label: 'Chance Epic',
                value: gb.lootEpic,
                min: 0.0,
                max: 0.5,
                onChanged: (v) => gb.lootEpic = v,
              ),
              const SizedBox(height: 8),
              // Thresholds summary
              const Text('Multiplier Thresholds (t1/t2/t3)'),
              Text(
                '${gb.lootT1.toStringAsFixed(2)} / ${gb.lootT2.toStringAsFixed(2)} / ${gb.lootT3.toStringAsFixed(2)}',
                overflow: TextOverflow.ellipsis,
              ),
              _slider(
                label: 't1',
                value: gb.lootT1,
                min: 0.2,
                max: 0.9,
                onChanged: (v) => gb.lootT1 = v,
              ),
              _slider(
                label: 't2',
                value: gb.lootT2,
                min: 0.3,
                max: 0.98,
                onChanged: (v) => gb.lootT2 = v,
              ),
              _slider(
                label: 't3',
                value: gb.lootT3,
                min: 0.5,
                max: 0.995,
                onChanged: (v) => gb.lootT3 = v,
              ),
              const SizedBox(height: 8),
              const Text('Multipliers (m1/m2/m3/m4)'),
              Text(
                '${gb.lootM1.toStringAsFixed(1)} / ${gb.lootM2.toStringAsFixed(1)} / ${gb.lootM3.toStringAsFixed(1)} / ${gb.lootM4.toStringAsFixed(1)}',
                overflow: TextOverflow.ellipsis,
              ),
              _slider(
                label: 'm1',
                value: gb.lootM1,
                min: 1.2,
                max: 3.0,
                onChanged: (v) => gb.lootM1 = v,
                fractionDigits: 1,
              ),
              _slider(
                label: 'm2',
                value: gb.lootM2,
                min: 1.2,
                max: 3.0,
                onChanged: (v) => gb.lootM2 = v,
                fractionDigits: 1,
              ),
              _slider(
                label: 'm3',
                value: gb.lootM3,
                min: 1.2,
                max: 3.0,
                onChanged: (v) => gb.lootM3 = v,
                fractionDigits: 1,
              ),
              _slider(
                label: 'm4',
                value: gb.lootM4,
                min: 1.2,
                max: 4.0,
                onChanged: (v) => gb.lootM4 = v,
                fractionDigits: 1,
              ),
              const SizedBox(height: 8),
              // Quick preview
              const Divider(height: 24),
              const Text('Quick Preview',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              Builder(builder: (_) {
                int xp(int minutes) {
                  final m = minutes.clamp(1, 10000);
                  final raw = gb.baseA * (m.toDouble().sqrt()) + gb.baseB;
                  return raw.round();
                }

                // Avoid using dart:math here; provide a small helper
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Base XP: 5m=${(gb.baseA * (5.0).sqrt() + gb.baseB).round()}, '
                        '15m=${(gb.baseA * (15.0).sqrt() + gb.baseB).round()}, '
                        '30m=${(gb.baseA * (30.0).sqrt() + gb.baseB).round()}'),
                    Text(
                        'Difficulty mult: easy=${gb.diffEasy.toStringAsFixed(2)}, '
                        'med=${gb.diffMedium.toStringAsFixed(2)}, '
                        'hard=${gb.diffHard.toStringAsFixed(2)}, '
                        'epic=${gb.diffEpic.toStringAsFixed(2)}'),
                  ],
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

extension on double {
  double sqrt() => MathHelper.sqrt(this);
}

class MathHelper {
  static double sqrt(double x) => x <= 0 ? 0 : (x).toDouble().sqrtNative();

  // Minimal sqrt implementation via Dart's math is avoided to keep imports light;
  // we rely on the engine's actual math. Here we just provide a stub for preview
  // text that uses a rough approximation to avoid pulling in dart:math here.
  static double _approxSqrt(double x) {
    double r = x;
    double prev;
    int i = 0;
    do {
      prev = r;
      r = 0.5 * (r + x / r);
      i++;
    } while ((r - prev).abs() > 1e-6 && i < 8);
    return r;
  }
}

extension _NativeSqrt on double {
  double sqrtNative() {
    // Use approximation to keep this file self-contained
    return MathHelper._approxSqrt(this);
  }
}
