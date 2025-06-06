import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/app_backup_service.dart';
import '../../lib/models/export_config.dart';

void main() {
  setUp(() async {
    // Set up mock SharedPreferences with test data
    SharedPreferences.setMockInitialValues({
      'tasks_data_v1': '''
        [
          {"id":"1","title":"Test Task","description":"","category":"","difficulty":"medium","xpReward":50,"createdAt":"2025-05-30T00:10:28.322455","completedAt":"2025-05-30T17:44:53.691436","isCompleted":true,"dueDate":null,"recurrencePattern":null,"parentTaskId":null,"skillId":"learning","scheduledTime":null,"weeklyDays":null,"repeatInterval":null,"endDate":null,"timeCostMinutes":10},
          {"id":"2","title":"Real Task","description":"desc","category":"","difficulty":"medium","xpReward":50,"createdAt":"2025-05-30T00:10:28.322455","completedAt":null,"isCompleted":false,"dueDate":null,"recurrencePattern":null,"parentTaskId":null,"skillId":"learning","scheduledTime":null,"weeklyDays":null,"repeatInterval":null,"endDate":null,"timeCostMinutes":10}
        ]
      '''
    });
  });

  test('Export filtering excludes test tasks by default', () async {
    final export = await AppBackupService.exportAllData(config: ExportConfig.backup);
    final tasks = export['tasks'] as List;
    // Only the real task should be included
    expect(tasks.length, 1);
    expect(tasks.first['title'], 'Real Task');
  });

  test('Export filtering includes test tasks if requested', () async {
    final export = await AppBackupService.exportAllData(
      config: ExportConfig(includeTestData: true),
    );
    final tasks = export['tasks'] as List;
    // Both tasks should be included
    expect(tasks.length, 2);
  });

  // Add more tests for other configs as needed!
}
