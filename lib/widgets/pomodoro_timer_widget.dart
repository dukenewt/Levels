import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/pomodoro_timer_service.dart';
import '../services/quiet_mode_service.dart';
import '../providers/settings_provider.dart';
import '../core/theme/app_design_tokens.dart';

class PomodoroTimerWidget extends StatefulWidget {
  const PomodoroTimerWidget({Key? key}) : super(key: key);

  @override
  State<PomodoroTimerWidget> createState() => _PomodoroTimerWidgetState();
}

class _PomodoroTimerWidgetState extends State<PomodoroTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pomodoroService = Provider.of<PomodoroTimerService>(context);
    final settings = Provider.of<SettingsProvider>(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme, pomodoroService),
            const SizedBox(height: AppDesignTokens.space4),
            _buildTimerDisplay(theme, pomodoroService, settings),
            const SizedBox(height: AppDesignTokens.space5),
            _buildControls(theme, pomodoroService),
            if (pomodoroService.isWorking) ...[
              const SizedBox(height: AppDesignTokens.space4),
              _buildQuietModeToggle(context, theme),
            ],
            const SizedBox(height: AppDesignTokens.space3),
            _buildSessionCounter(theme, pomodoroService),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, PomodoroTimerService service) {
    String title;
    IconData icon;
    Color color;

    switch (service.state) {
      case PomodoroState.workSession:
        title = 'Focus Time';
        icon = Icons.work_outline;
        color = Colors.orange;
        break;
      case PomodoroState.shortBreak:
        title = 'Short Break';
        icon = Icons.free_breakfast_outlined;
        color = Colors.green;
        break;
      case PomodoroState.longBreak:
        title = 'Long Break';
        icon = Icons.beach_access_outlined;
        color = Colors.blue;
        break;
      case PomodoroState.paused:
        title = 'Paused';
        icon = Icons.pause_circle_outline;
        color = Colors.grey;
        break;
      case PomodoroState.stopped:
        title = 'Pomodoro Timer';
        icon = Icons.timer_outlined;
        color = theme.colorScheme.primary;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: AppDesignTokens.space2),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerDisplay(
    ThemeData theme,
    PomodoroTimerService service,
    SettingsProvider settings,
  ) {
    final isRunning = service.isRunning;
    final reducedMotion = settings.reducedMotion;

    return AnimatedBuilder(
      animation: isRunning && !reducedMotion
          ? _pulseAnimation
          : const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return Transform.scale(
          scale: isRunning && !reducedMotion ? _pulseAnimation.value : 1.0,
          child: SizedBox(
            width: 240,
            height: 240,
            child: CustomPaint(
              painter: PomodoroClockPainter(
                progress: service.progress,
                isWorking: service.isWorking,
                state: service.state,
                colorScheme: theme.colorScheme,
                reducedMotion: reducedMotion,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      service.formattedTime,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.space2),
                    Text(
                      '${service.remainingMinutes} min remaining',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls(ThemeData theme, PomodoroTimerService service) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (service.state == PomodoroState.stopped) ...[
          _buildActionButton(
            icon: Icons.play_arrow,
            label: 'Start Focus',
            color: Colors.orange,
            onPressed: service.startWorkSession,
          ),
        ] else if (service.state == PomodoroState.paused) ...[
          _buildActionButton(
            icon: Icons.play_arrow,
            label: 'Resume',
            color: Colors.green,
            onPressed: service.resume,
          ),
          const SizedBox(width: AppDesignTokens.space3),
          _buildActionButton(
            icon: Icons.stop,
            label: 'Stop',
            color: Colors.red,
            onPressed: service.stop,
          ),
        ] else ...[
          _buildActionButton(
            icon: Icons.pause,
            label: 'Pause',
            color: Colors.blue,
            onPressed: service.pause,
          ),
          const SizedBox(width: AppDesignTokens.space3),
          _buildActionButton(
            icon: Icons.stop,
            label: 'Stop',
            color: Colors.red,
            onPressed: service.stop,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.space4,
          vertical: AppDesignTokens.space3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
        ),
      ),
    );
  }

  Widget _buildQuietModeToggle(BuildContext context, ThemeData theme) {
    final quietMode = Provider.of<QuietModeService>(context);

    return Container(
      padding: const EdgeInsets.all(AppDesignTokens.space3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            quietMode.isActive
                ? Icons.notifications_off
                : Icons.notifications_active,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppDesignTokens.space2),
          Text(
            'Quiet Mode',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppDesignTokens.space2),
          Switch(
            value: quietMode.isActive,
            onChanged: (value) {
              if (value) {
                quietMode.enable(duration: QuietModeService.duration25Minutes);
              } else {
                quietMode.disable();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCounter(ThemeData theme, PomodoroTimerService service) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: AppDesignTokens.space1),
        Text(
          '${service.sessionsCompleted} ${service.sessionsCompleted == 1 ? 'session' : 'sessions'} completed',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class PomodoroClockPainter extends CustomPainter {
  final double progress;
  final bool isWorking;
  final PomodoroState state;
  final ColorScheme colorScheme;
  final bool reducedMotion;

  PomodoroClockPainter({
    required this.progress,
    required this.isWorking,
    required this.state,
    required this.colorScheme,
    required this.reducedMotion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 16;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = colorScheme.surfaceVariant.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      // Color based on state
      Color progressColor;
      switch (state) {
        case PomodoroState.workSession:
          progressColor = Colors.orange;
          break;
        case PomodoroState.shortBreak:
          progressColor = Colors.green;
          break;
        case PomodoroState.longBreak:
          progressColor = Colors.blue;
          break;
        default:
          progressColor = colorScheme.primary;
      }

      progressPaint.shader = SweepGradient(
        colors: [
          progressColor.withOpacity(0.3),
          progressColor,
          progressColor,
        ],
        stops: const [0.0, 0.5, 1.0],
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + (2 * math.pi * progress),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }

    // Draw clock tick marks (12 marks like a clock)
    final tickPaint = Paint()
      ..color = colorScheme.onSurfaceVariant.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final startRadius = radius - 8;
      final endRadius = radius - 2;

      final start = Offset(
        center.dx + startRadius * math.cos(angle - math.pi / 2),
        center.dy + startRadius * math.sin(angle - math.pi / 2),
      );

      final end = Offset(
        center.dx + endRadius * math.cos(angle - math.pi / 2),
        center.dy + endRadius * math.sin(angle - math.pi / 2),
      );

      canvas.drawLine(start, end, tickPaint);
    }
  }

  @override
  bool shouldRepaint(PomodoroClockPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.state != state ||
        oldDelegate.isWorking != isWorking;
  }
}
