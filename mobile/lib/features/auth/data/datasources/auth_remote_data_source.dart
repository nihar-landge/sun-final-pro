import 'package:feedback_app/core/constants/api_constants.dart';
import 'package:feedback_app/core/network/api_client.dart';

/// Talks to auth-service through the API gateway.
class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource(this.apiClient);

  Future<void> register({required String name, required String email, required String password}) async {
    await apiClient.post(
      Uri.parse(ApiConstants.register),
      body: {'name': name, 'email': email, 'password': password},
    );
  }

  Future<Map<String, dynamic>> login({required String email, required String password}) {
    return apiClient.post(
      Uri.parse(ApiConstants.login),
      body: {'email': email, 'password': password},
    );
  }

  Future<Map<String, dynamic>> me() {
    return apiClient.get(Uri.parse(ApiConstants.me), authenticated: true);
  }
}
