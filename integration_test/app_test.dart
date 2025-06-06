import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailyxp/main.dart' as app;  // Update this to match your app's actual name

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('App starts without crashing', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Just verify the app loads and shows some expected content
      // Look for something that should always be there, like a title or main button
      expect(find.text('Daily XP'), findsOneWidget);  // Adjust based on your app's actual title
      
      // This test succeeds if the app starts without throwing exceptions
    });

    testWidgets('Can navigate through basic app flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Add more specific tests based on your app's actual UI
      // For example, test that you can tap a button without the app crashing
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton);
        await tester.pumpAndSettle();
        // Verify that tapping the button did something reasonable
      }
    });
  });
}