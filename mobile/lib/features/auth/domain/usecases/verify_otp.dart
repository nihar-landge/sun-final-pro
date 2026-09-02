import 'package:feedback_app/features/auth/domain/repositories/auth_repository.dart';

class VerifyOtp {
  final AuthRepository repository;

  VerifyOtp(this.repository);

  Future<AuthSession> call({
    required String phone,
    required String code,
    String? name,
  }) =>
      repository.verifyOtp(phone: phone, code: code, name: name);
}
