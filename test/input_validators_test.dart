import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/core/utils/input_validators.dart';

void main() {
  group('InputValidators.email', () {
    test('returns null for valid email', () {
      expect(InputValidators.email('user@example.com'), isNull);
    });

    test('returns a message for invalid email', () {
      expect(InputValidators.email('invalid'), isNotNull);
    });
  });

  group('InputValidators.password', () {
    test('returns null for password with at least 6 characters', () {
      expect(InputValidators.password('secret1'), isNull);
    });

    test('returns a message for short password', () {
      expect(InputValidators.password('123'), isNotNull);
    });
  });
}
