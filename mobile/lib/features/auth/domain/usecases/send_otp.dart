import 'package:feedback_app/features/auth/domain/repositories/auth_repository.dart';

class SendOtp {
  final AuthRepository repository;

  SendOtp(this.repository);

  /// Returns true when the OTP was dispatched successfully.
  Future<bool> call(String phone) => repository.sendOtp(phone);
}
