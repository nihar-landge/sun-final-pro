class Validators {
  Validators._();

  static final RegExp _phone = RegExp(r'^\d{10,15}$');
  static final RegExp _otp = RegExp(r'^\d{6}$');

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your phone number';
    if (!_phone.hasMatch(value.trim())) return 'Phone must be 10-15 digits';
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter the OTP';
    if (!_otp.hasMatch(value.trim())) return 'OTP must be 6 digits';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your name';
    if (value.trim().length > 100) return 'Name must be at most 100 characters';
    return null;
  }
}
