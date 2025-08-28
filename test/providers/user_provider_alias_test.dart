import 'package:flutter_test/flutter_test.dart';
import 'package:dailyxp/providers/user_provider.dart' as canonical;

void main() {
  test('canonical UserProvider symbol is exported', () {
    // Presence test: reference the type without instantiation
    expect(canonical.UserProvider, isNotNull);
  });
}
