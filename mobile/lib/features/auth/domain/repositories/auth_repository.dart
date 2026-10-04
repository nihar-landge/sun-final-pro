import 'package:feedback_app/features/auth/domain/entities/user.dart';

/// The authenticated session: a single 24h access token plus the user.
class AuthSession {
  final String accessToken;
  final int expiresIn;
  final User user;

  const AuthSession({
    required this.accessToken,
    required this.expiresIn,
    required this.user,
  });
}

abstract interface class AuthRepository {
  /// Creates a new citizen account with [name], [email] and [password].
  Future<void> register({required String name, required String email, required String password});

  /// Logs in with [email] and [password], persists the session and returns it.
  Future<AuthSession> login({required String email, required String password});

  /// Restores a persisted session (returns null when none exists or it is
  /// no longer valid).
  Future<AuthSession?> restoreSession();

  /// Clears the local session (stateless JWT — nothing to revoke server-side).
  Future<void> logout();
}
