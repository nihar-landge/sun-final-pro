import 'package:feedback_app/features/auth/domain/repositories/auth_repository.dart';

class RestoreSession {
  final AuthRepository repository;

  RestoreSession(this.repository);

  /// Null when no valid stored session exists.
  Future<AuthSession?> call() => repository.restoreSession();
}
