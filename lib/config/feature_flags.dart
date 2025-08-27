/// Feature flags for safely testing new architecture
/// Allows gradual rollout and easy rollback

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FeatureFlags {
  static const String _logPrefix = 'FeatureFlags';

  // Architecture feature flags
  static const bool enableNewTalentPerkController =
      kDebugMode; // Only in debug for now
  static const bool enablePureEffectEngine =
      kDebugMode; // Only in debug for now
  static const bool enableCompletionPipeline = false; // Not ready yet
  static const bool enableArchitectureTests =
      kDebugMode; // Testing in debug only

  // UI feature flags
  static const bool enableNewTalentDialog = false; // Not ready yet
  static const bool enableAnimationOrchestrator = false; // Future work
  static const bool enableReducedMotionUI = false; // Future work

  // Safety feature flags
  static const bool enableFallbackToOldSystem = true; // Always have fallback
  static const bool enableDetailedLogging = kDebugMode; // Debug logging
  static const bool enableIntegrationTesting = kDebugMode; // Run tests in debug

  /// Check if new talent/perk system should be used
  static bool shouldUseNewTalentSystem() {
    return enableNewTalentPerkController && kDebugMode;
  }

  /// Check if pure effect engine should be used
  static bool shouldUsePureEffectEngine() {
    return enablePureEffectEngine && kDebugMode;
  }

  /// Check if completion pipeline should be used
  static bool shouldUseCompletionPipeline() {
    return enableCompletionPipeline && kDebugMode;
  }

  /// Check if architecture integration tests should run
  static bool shouldRunIntegrationTests() {
    return enableArchitectureTests && enableIntegrationTesting;
  }

  /// Check if detailed logging should be enabled
  static bool shouldLogDetailed() {
    return enableDetailedLogging && kDebugMode;
  }

  /// Check if fallback to old system is enabled
  static bool hasFallbackToOldSystem() {
    return enableFallbackToOldSystem;
  }

  /// Get feature flag status for debugging
  static Map<String, dynamic> getStatus() {
    return {
      'new_talent_controller': shouldUseNewTalentSystem(),
      'pure_effect_engine': shouldUsePureEffectEngine(),
      'completion_pipeline': shouldUseCompletionPipeline(),
      'integration_tests': shouldRunIntegrationTests(),
      'detailed_logging': shouldLogDetailed(),
      'fallback_enabled': hasFallbackToOldSystem(),
      'debug_mode': kDebugMode,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Log feature flag status
  static void logStatus() {
    if (shouldLogDetailed()) {
      final status = getStatus();
      debugPrint('$_logPrefix: Current feature flags: $status');
    }
  }

  /// Check if a specific feature is enabled with fallback
  static bool isEnabled(String featureName, {bool defaultValue = false}) {
    switch (featureName) {
      case 'new_talent_controller':
        return shouldUseNewTalentSystem();
      case 'pure_effect_engine':
        return shouldUsePureEffectEngine();
      case 'completion_pipeline':
        return shouldUseCompletionPipeline();
      case 'integration_tests':
        return shouldRunIntegrationTests();
      case 'detailed_logging':
        return shouldLogDetailed();
      case 'fallback_enabled':
        return hasFallbackToOldSystem();
      default:
        if (shouldLogDetailed()) {
          debugPrint(
              '$_logPrefix: Unknown feature flag: $featureName, using default: $defaultValue');
        }
        return defaultValue;
    }
  }
}

/// Mixin for widgets that need feature flag access
mixin FeatureFlagMixin {
  bool get useNewTalentSystem => FeatureFlags.shouldUseNewTalentSystem();
  bool get usePureEffectEngine => FeatureFlags.shouldUsePureEffectEngine();
  bool get useCompletionPipeline => FeatureFlags.shouldUseCompletionPipeline();
  bool get shouldRunTests => FeatureFlags.shouldRunIntegrationTests();
  bool get hasLogDetailed => FeatureFlags.shouldLogDetailed();
  bool get hasFallback => FeatureFlags.hasFallbackToOldSystem();
}

/// Widget that shows feature flag status in debug mode
class FeatureFlagDebugDisplay extends StatelessWidget {
  const FeatureFlagDebugDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final status = FeatureFlags.getStatus();

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: Border.all(color: Colors.blue, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Feature Flags (Debug)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          ...status.entries.where((e) => e.key != 'timestamp').map((e) => Text(
                '${e.key}: ${e.value}',
                style: const TextStyle(fontSize: 10),
              )),
        ],
      ),
    );
  }
}
