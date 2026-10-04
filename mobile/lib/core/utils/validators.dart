import 'package:feedback_app/l10n/gen/app_localizations.dart';

class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return l10n.validationEnterEmail;
    if (!_email.hasMatch(value.trim())) return l10n.validationEmailInvalid;
    return null;
  }

  static String? password(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.validationEnterPassword;
    if (value.length < 8) return l10n.validationPasswordLength;
    return null;
  }

  static String? name(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return l10n.validationEnterName;
    if (value.trim().length > 100) return l10n.validationNameLength;
    return null;
  }
}
