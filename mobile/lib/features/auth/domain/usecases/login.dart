import 'package:feedback_app/features/auth/domain/repositories/auth_repository.dart';

class Login {
  final AuthRepository repository;

  Login(this.repository);

  Future<AuthSession> call({required String email, required String password}) =>
      repository.login(email: email, password: password);
}
