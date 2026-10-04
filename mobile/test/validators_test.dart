import 'dart:ui';

import 'package:feedback_app/core/utils/validators.dart';
import 'package:feedback_app/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('Validators.email', () {
    test('accepts normal addresses', () {
      expect(Validators.email('nihar@example.com', l10n), isNull);
      expect(Validators.email('a.b+tag@sub.domain.in', l10n), isNull);
    });

    test('rejects malformed and empty input', () {
      expect(Validators.email('not-an-email', l10n), isNotNull);
      expect(Validators.email('missing@tld', l10n), isNotNull);
      expect(Validators.email('two@@at.com', l10n), isNotNull);
      expect(Validators.email('', l10n), isNotNull);
      expect(Validators.email(null, l10n), isNotNull);
    });
  });

  group('Validators.password', () {
    test('accepts passwords of 8+ characters', () {
      expect(Validators.password('s3cretPass!', l10n), isNull);
      expect(Validators.password('12345678', l10n), isNull);
    });

    test('rejects short and empty passwords', () {
      expect(Validators.password('1234567', l10n), isNotNull);
      expect(Validators.password('', l10n), isNotNull);
      expect(Validators.password(null, l10n), isNotNull);
    });
  });
}
