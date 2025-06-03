import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:dailyxp/models/task.dart';
import 'package:dailyxp/models/task_results.dart';
import 'package:dailyxp/providers/task_provider.dart';
import 'package:dailyxp/widgets/task_tile.dart';

// This annotation generates mock classes for us automatically
// It's like creating fake versions of your providers that you can control completely
@GenerateMocks([TaskProvider])
import 'task_tile_test.mocks.dart';

void main() {
  group('TaskTile Error Handling Tests', () {
    testWidgets('shows success message when task completion succeeds', (WidgetTester tester) async {
      // Arrange: Set up our test scenario
      final task = createSampleTask();
      final mockProvider = MockTaskProvider();
      
      // Configure our mock to simulate successful task completion
      when(mockProvider.completeTask(task.id)).thenAnswer((_) async {
        return TaskCompletionResult.success(task.copyWith(isCompleted: true));
      });
      
      // Build our widget in the test environment
      await tester.pumpWidget(createTestableTaskTile(
        task: task,
        mockTaskProvider: mockProvider,
      ));
      
      // Act: Simulate the user tapping the completion button
      final completionButton = find.byKey(const Key('task-complete-button'));
      print('Found: \\${completionButton.evaluate().length}\\ widgets with key task-complete-button');
      await tester.tap(completionButton);
      await tester.pumpAndSettle();
      
      // Assert: Verify that the success message appears
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Task completed! +50 XP'), findsOneWidget);
      verify(mockProvider.completeTask(task.id)).called(1);
    });

    testWidgets('shows appropriate error message when task is not found', (WidgetTester tester) async {
      final task = createSampleTask();
      final mockProvider = MockTaskProvider();
      
      when(mockProvider.completeTask(task.id)).thenAnswer((_) async {
        return TaskCompletionResult.failure(
          'Task not found',
          TaskCompletionError.taskNotFound,
        );
      });
      
      await tester.pumpWidget(createTestableTaskTile(
        task: task,
        mockTaskProvider: mockProvider,
      ));
      await tester.tap(find.byKey(const Key('task-complete-button')));
      await tester.pumpAndSettle();
      
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('This task no longer exists. Refreshing your task list.'), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, Colors.orange);
    });

    testWidgets('shows retry option when storage failure occurs', (WidgetTester tester) async {
      final task = createSampleTask();
      final mockProvider = MockTaskProvider();
      
      when(mockProvider.completeTask(task.id)).thenAnswer((_) async {
        return TaskCompletionResult.failure(
          'Failed to save task completion. Please try again.',
          TaskCompletionError.storageFailure,
        );
      });
      
      await tester.pumpWidget(createTestableTaskTile(
        task: task,
        mockTaskProvider: mockProvider,
      ));
      await tester.tap(find.byKey(const Key('task-complete-button')));
      await tester.pumpAndSettle();
      
      expect(find.text('Failed to save task completion. Please try again.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      verify(mockProvider.completeTask(task.id)).called(2);
    });

    testWidgets('plays completion animation when task succeeds', (WidgetTester tester) async {
      final task = createSampleTask();
      final mockProvider = MockTaskProvider();
      
      when(mockProvider.completeTask(task.id)).thenAnswer((_) async {
        return TaskCompletionResult.success(task.copyWith(isCompleted: true));
      });
      
      await tester.pumpWidget(createTestableTaskTile(
        task: task,
        mockTaskProvider: mockProvider,
      ));
      expect(find.byIcon(Icons.check), findsNothing);
      await tester.tap(find.byKey(const Key('task-complete-button')));
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      await tester.pumpWidget(createTestableTaskTile(
        task: task.copyWith(isCompleted: true),
        mockTaskProvider: mockProvider,
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
/// Creates a testable version of TaskTile with controlled dependencies
/// This is like building a laboratory where we can control all the variables
Widget createTestableTaskTile({
  required Task task,
  required MockTaskProvider mockTaskProvider,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ChangeNotifierProvider<TaskProvider>.value(
        value: mockTaskProvider,
        child: TaskTile(task: task),
      ),
    ),
  );
}

/// Creates a sample task for testing purposes
/// Having consistent test data makes our tests more reliable and easier to understand
Task createSampleTask() {
  return Task(
    id: 'test-task-123',
    title: 'Test Task',
    description: 'A task for testing purposes',
    category: 'Testing',
    xpReward: 50,
    createdAt: DateTime.now(),
  );
}