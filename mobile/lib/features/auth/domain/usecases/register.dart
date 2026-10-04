import 'package:feedback_app/features/auth/domain/repositories/auth_repository.dart';

class Register {
  final AuthRepository repository;

  Register(this.repository);

  Future<void> call({required String name, required String email, required String password}) =>
      repository.register(name: name, email: email, password: password);
}
