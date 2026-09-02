import 'package:feedback_app/features/auth/domain/entities/user.dart';

/// Token bundle returned on successful OTP verification.
class AuthSession {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final User user;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });
}

abstract interface class AuthRepository {
  /// Sends a login OTP to [phone]. Returns true when the OTP was dispatched.
  Future<bool> sendOtp(String phone);

  /// Verifies [code] for [phone], persists the session and returns it.
  Future<AuthSession> verifyOtp({required String phone, required String code, String? name});

  /// Restores a persisted session (returns null when none exists or it is
  /// no longer valid).
  Future<AuthSession?> restoreSession();

  /// Revokes the refresh token on the backend and clears local storage.
  Future<void> logout();
}
