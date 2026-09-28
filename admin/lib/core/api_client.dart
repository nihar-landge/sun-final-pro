import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Minimal API client for the admin panel. Unwraps the ApiResponse envelope,
/// attaches the stored token and refreshes once on 401.
class AdminApiClient {
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  static const _accessKey = 'admin_access_token';
  static const _refreshKey = 'admin_refresh_token';

  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String get baseUrl => _baseUrl;

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  Future<String?> _readAccess() => _storage.read(key: _accessKey);

  /// Returns the `data` of a successful ApiResponse.
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Object? body,
    bool authenticated = true,
  }) async {
    var response = await _send(path, method, body, authenticated);
    if (authenticated && response.statusCode == 401) {
      if (await _refresh()) {
        response = await _send(path, method, body, authenticated);
      }
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      throw AdminApiException(
        decoded is Map<String, dynamic>
            ? decoded['message'] as String? ?? 'Request failed'
            : 'Request failed',
        statusCode: response.statusCode,
      );
    }
    return decoded['data'];
  }

  Future<http.Response> _send(
      String path, String method, Object? body, bool authenticated) async {
    final headers = {'Content-Type': 'application/json'};
    if (authenticated) {
      final token = await _readAccess();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    final uri = Uri.parse('$_baseUrl$path');
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    try {
      return await http.Response.fromStream(await _client.send(request));
    } catch (_) {
      throw const AdminApiException('Could not reach the server');
    }
  }

  Future<bool> _refresh() async {
    final refresh = await _storage.read(key: _refreshKey);
    if (refresh == null) return false;
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/token/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refresh}),
      );
      if (response.statusCode != 200) {
        await clearTokens();
        return false;
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes))['data'];
      await saveTokens(access: data['accessToken'], refresh: data['refreshToken']);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class AdminApiException implements Exception {
  final String message;
  final int? statusCode;

  const AdminApiException(this.message, {this.statusCode});
}
