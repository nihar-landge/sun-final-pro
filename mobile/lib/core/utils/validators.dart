import 'package:feedback_app/l10n/gen/app_localizations.dart';

class Validators {
  Validators._();

  static final RegExp _phone = RegExp(r'^\d{10,15}$');
  static final RegExp _otp = RegExp(r'^\d{6}$');

  static String? phone(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return l10n.validationEnterPhone;
    if (!_phone.hasMatch(value.trim())) return l10n.validationPhoneDigits;
    return null;
  }

  static String? otp(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return l10n.validationEnterOtp;
    if (!_otp.hasMatch(value.trim())) return l10n.validationOtpDigits;
    return null;
  }

  static String? name(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return l10n.validationEnterName;
    if (value.trim().length > 100) return l10n.validationNameLength;
    return null;
  }
}
