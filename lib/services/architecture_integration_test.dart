/// Integration test service for new architecture
/// Tests new architecture alongside existing system without breaking anything

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../controllers/talent_perk_controller.dart';
import '../services/pure_effect_engine.dart';
import '../models/effect.dart';

/// Service to test new architecture integration safely
class ArchitectureIntegrationTest {
  static const String _logPrefix = 'ArchitectureIntegration';

  /// Test the new TalentPerkController with real user data
  static Future<Map<String, dynamic>> testTalentPerkController({
    required User user,
    required TalentPerkController controller,
  }) async {
    final results = <String, dynamic>{
      'success': false,
      'errors': <String>[],
      'comparisons': <String, dynamic>{},
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      _log('Testing TalentPerkController with user level ${user.level}');

      // Test 1: Controller can handle user update
      await controller.updateUser(user);

      if (controller.currentUser?.id != user.id) {
        results['errors'].add('Controller did not update user correctly');
        return results;
      }

      // Test 2: Effect preview works
      final healthPreview = await controller.getEffectPreviewForContext(
        category: 'Health',
      );

      final workPreview = await controller.getEffectPreviewForContext(
        category: 'Work',
      );

      // Test 3: XP preview calculation
      final xpPreview = await controller.calculateXPPreview(
        baseXP: 100,
        category: 'Health',
        difficulty: 'medium',
      );

      // Test 4: State consistency
      final state = controller.state;
      final hasActiveEffects = state.activeEffects.isNotEmpty;
      final hasUnlockedPerks = state.unlockedPerks.isNotEmpty;

      results['comparisons'] = {
        'user_level': user.level,
        'controller_level': controller.currentUser?.level,
        'health_preview': healthPreview,
        'work_preview': workPreview,
        'xp_preview': xpPreview,
        'base_xp': 100,
        'xp_multiplier': (xpPreview / 100.0),
        'has_active_effects': hasActiveEffects,
        'active_effects_count': state.activeEffects.length,
        'has_unlocked_perks': hasUnlockedPerks,
        'unlocked_perks_count': state.unlockedPerks.length,
        'needs_talent_choice': state.needsTalentChoice,
        'talent_choice_level': state.talentChoiceLevel,
      };

      _log('Controller test completed successfully');
      _log('Active effects: ${state.activeEffects.length}');
      _log('Unlocked perks: ${state.unlockedPerks.length}');
      _log('XP multiplier: ${(xpPreview / 100.0).toStringAsFixed(2)}x');

      results['success'] = true;
    } catch (e, stackTrace) {
      final error = 'Controller test failed: $e';
      results['errors'].add(error);
      _log('ERROR: $error');
      _log('Stack trace: $stackTrace');
    }

    return results;
  }

  /// Test the pure effect engine with real data
  static Map<String, dynamic> testPureEffectEngine({
    required User user,
    String testCategory = 'Health',
  }) {
    final results = <String, dynamic>{
      'success': false,
      'errors': <String>[],
      'effects_data': <String, dynamic>{},
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      _log('Testing PureEffectEngine with user level ${user.level}');

      // Test effect context creation
      final context = EffectContext.forPreview(
        category: testCategory,
        additional: {'user_level': user.level},
      );

      // Test effect evaluation
      final effectResults = PureEffectEngine.evaluateEffects(
        user: user,
        context: context,
      );

      // Test effect preview
      final preview = PureEffectEngine.getEffectPreview(
        user: user,
        category: testCategory,
      );

      results['effects_data'] = {
        'context_created': context.isNotEmpty,
        'context_keys': context.keys.toList(),
        'effects_evaluated': effectResults.hasEffects,
        'applied_effects_count': effectResults.appliedEffects.length,
        'property_modifiers': effectResults.propertyModifiers,
        'conditional_values': effectResults.conditionalValues,
        'effect_descriptions': effectResults.effectDescriptions,
        'preview_items': preview,
        'preview_count': preview.length,
      };

      _log('Effect engine test completed successfully');
      _log('Applied effects: ${effectResults.appliedEffects.length}');
      _log('Preview items: ${preview.length}');

      results['success'] = true;
    } catch (e, stackTrace) {
      final error = 'Effect engine test failed: $e';
      results['errors'].add(error);
      _log('ERROR: $error');
      _log('Stack trace: $stackTrace');
    }

    return results;
  }

  /// Compare new architecture results with existing system (when available)
  static Map<String, dynamic> compareWithExistingSystem({
    required Map<String, dynamic> newResults,
    Map<String, dynamic>? existingResults,
  }) {
    final comparison = <String, dynamic>{
      'has_existing_data': existingResults != null,
      'new_system_working': newResults['success'] == true,
      'differences': <String, dynamic>{},
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (existingResults != null) {
      // Compare specific fields when both systems are available
      _log('Comparing new system with existing system');

      // This is where we'd add specific comparisons
      // For now, just log that both systems are available
      comparison['differences'] = {
        'note': 'Both systems available for comparison',
        'new_success': newResults['success'],
        'existing_success': existingResults['success'],
      };
    } else {
      _log('Only new system tested (existing system not provided)');
    }

    return comparison;
  }

  /// Run a comprehensive integration test
  static Future<Map<String, dynamic>> runFullIntegrationTest({
    required User user,
    required TalentPerkController controller,
    bool verbose = false,
  }) async {
    final results = <String, dynamic>{
      'overall_success': false,
      'test_results': <String, dynamic>{},
      'timestamp': DateTime.now().toIso8601String(),
    };

    _log('Starting full integration test for user ${user.id}');

    try {
      // Test 1: TalentPerkController
      final controllerResults = await testTalentPerkController(
        user: user,
        controller: controller,
      );
      results['test_results']['controller'] = controllerResults;

      // Test 2: PureEffectEngine
      final engineResults = testPureEffectEngine(user: user);
      results['test_results']['effect_engine'] = engineResults;

      // Test 3: Integration comparison
      final comparisonResults = compareWithExistingSystem(
        newResults: {
          'controller': controllerResults,
          'engine': engineResults,
          'success': controllerResults['success'] && engineResults['success'],
        },
      );
      results['test_results']['comparison'] = comparisonResults;

      // Overall success
      final controllerSuccess = controllerResults['success'] == true;
      final engineSuccess = engineResults['success'] == true;
      results['overall_success'] = controllerSuccess && engineSuccess;

      if (results['overall_success']) {
        _log('✅ Full integration test PASSED');
      } else {
        _log('❌ Full integration test FAILED');
        _log('Controller success: $controllerSuccess');
        _log('Engine success: $engineSuccess');
      }

      if (verbose) {
        _log('Detailed results: $results');
      }
    } catch (e, stackTrace) {
      results['test_results']['error'] = {
        'message': e.toString(),
        'stack_trace': stackTrace.toString(),
      };
      _log('FATAL ERROR in integration test: $e');
    }

    return results;
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('$_logPrefix: $message');
    }
  }
}

/// Widget to display integration test results in debug mode
class IntegrationTestDisplay extends StatelessWidget {
  final Map<String, dynamic> testResults;

  const IntegrationTestDisplay({
    Key? key,
    required this.testResults,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final success = testResults['overall_success'] == true;

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: success
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        border: Border.all(
          color: success ? Colors.green : Colors.red,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Architecture Integration Test',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: success ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            success ? '✅ PASSED' : '❌ FAILED',
            style: TextStyle(
              color: success ? Colors.green : Colors.red,
              fontSize: 11,
            ),
          ),
          if (testResults['test_results'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Controller: ${_getStatus(testResults['test_results']['controller'])}',
              style: const TextStyle(fontSize: 10),
            ),
            Text(
              'Engine: ${_getStatus(testResults['test_results']['effect_engine'])}',
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatus(Map<String, dynamic>? result) {
    if (result == null) return 'Unknown';
    return result['success'] == true ? 'OK' : 'Failed';
  }
}
