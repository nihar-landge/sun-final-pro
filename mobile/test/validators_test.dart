import 'dart:ui';

import 'package:feedback_app/core/utils/validators.dart';
import 'package:feedback_app/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('Validators.phone', () {
    test('accepts 10-15 digit numbers', () {
      expect(Validators.phone('9876543210', l10n), isNull);
      expect(Validators.phone('123456789012345', l10n), isNull);
    });

    test('rejects too-short, non-numeric and empty input', () {
      expect(Validators.phone('12345', l10n), isNotNull);
      expect(Validators.phone('98765432a0', l10n), isNotNull);
      expect(Validators.phone('', l10n), isNotNull);
      expect(Validators.phone(null, l10n), isNotNull);
    });
  });

  group('Validators.otp', () {
    test('accepts exactly 6 digits', () {
      expect(Validators.otp('123456', l10n), isNull);
    });

    test('rejects wrong lengths and non-digits', () {
      expect(Validators.otp('12345', l10n), isNotNull);
      expect(Validators.otp('1234567', l10n), isNotNull);
      expect(Validators.otp('12a456', l10n), isNotNull);
    });
  });
}
