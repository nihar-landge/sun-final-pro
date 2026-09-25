import 'package:feedback_app/features/auth/domain/repositories/auth_repository.dart';

class SendOtp {
  final AuthRepository repository;

  SendOtp(this.repository);

  /// Returns the dev-echoed OTP (null in production).
  Future<String?> call(String phone) => repository.sendOtp(phone);
}
