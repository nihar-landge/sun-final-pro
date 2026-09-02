import 'package:feedback_app/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.phone', () {
    test('accepts 10-15 digit numbers', () {
      expect(Validators.phone('9876543210'), isNull);
      expect(Validators.phone('123456789012345'), isNull);
    });

    test('rejects too-short, non-numeric and empty input', () {
      expect(Validators.phone('12345'), isNotNull);
      expect(Validators.phone('98765432a0'), isNotNull);
      expect(Validators.phone(''), isNotNull);
      expect(Validators.phone(null), isNotNull);
    });
  });

  group('Validators.otp', () {
    test('accepts exactly 6 digits', () {
      expect(Validators.otp('123456'), isNull);
    });

    test('rejects wrong lengths and non-digits', () {
      expect(Validators.otp('12345'), isNotNull);
      expect(Validators.otp('1234567'), isNotNull);
      expect(Validators.otp('12a456'), isNotNull);
    });
  });
}
