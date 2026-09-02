import 'package:feedback_app/core/constants/api_constants.dart';
import 'package:feedback_app/core/network/api_client.dart';

/// Talks to auth-service through the API gateway.
class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource(this.apiClient);

  /// Returns the dev-echoed OTP when the backend runs with dev-echo enabled.
  Future<String?> sendOtp(String phone) async {
    final data = await apiClient.post(
      Uri.parse(ApiConstants.sendOtp),
      body: {'phone': phone},
    );
    return data['devOtp'] as String?;
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
    String? name,
  }) {
    return apiClient.post(
      Uri.parse(ApiConstants.verifyOtp),
      body: {'phone': phone, 'code': code, 'name': name},
    );
  }

  Future<Map<String, dynamic>> me() {
    return apiClient.get(Uri.parse(ApiConstants.me), authenticated: true);
  }

  Future<void> logout(String refreshToken) async {
    await apiClient.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/logout'),
      body: {'refreshToken': refreshToken},
    );
  }
}
