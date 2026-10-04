class ApiConstants {
  ApiConstants._();

  /// Base URL of the API gateway.
  ///
  /// - Android emulator: 10.0.2.2 is the host machine's loopback.
  /// - iOS simulator: use http://localhost:8080
  /// - Physical device: use your machine's LAN IP.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );

  // Auth endpoints
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String me = '$baseUrl/auth/me';

  // Feature endpoints
  static const String pollsBase = '$baseUrl/polls';
  static const String feedbackBase = '$baseUrl/feedback';
}
