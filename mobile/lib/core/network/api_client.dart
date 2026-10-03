import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:feedback_app/core/constants/api_constants.dart';
import 'package:feedback_app/core/errors/exceptions.dart';
import 'package:feedback_app/core/network/token_store.dart';

/// HTTP wrapper that unwraps the backend's ApiResponse envelope, attaches
/// the stored access token, and transparently refreshes it once on a 401.
class ApiClient {
  final http.Client _client;
  final TokenStore? tokenStore;

  ApiClient({http.Client? client, this.tokenStore}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> get(
    Uri uri, {
    Map<String, String>? headers,
    bool authenticated = false,
  }) async {
    final response = await _send(
      (token) => _client.get(uri, headers: _headers(headers, token)),
      authenticated: authenticated,
    );
    return _unwrap(response);
  }

  Future<Map<String, dynamic>> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    bool authenticated = false,
  }) async {
    final response = await _send(
      (token) => _client.post(
            uri,
            headers: _headers(headers, token),
            body: jsonEncode(body ?? {}),
          ),
      authenticated: authenticated,
    );
    return _unwrap(response);
  }

  /// For list/array payloads (returns the raw `data` value).
  Future<dynamic> getDynamic(
    Uri uri, {
    Map<String, String>? headers,
    bool authenticated = false,
  }) async {
    final response = await _send(
      (token) => _client.get(uri, headers: _headers(headers, token)),
      authenticated: authenticated,
    );
    final decoded = _decode(response);
    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      throw ServerException(
        decoded is Map<String, dynamic>
            ? decoded['message'] as String? ?? 'Request failed'
            : _plainText(decoded) ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }
    return decoded['data'];
  }

  Map<String, String> _headers(Map<String, String>? headers, String? token) {
    final all = {...?headers, 'Content-Type': 'application/json'};
    if (token != null) {
      all['Authorization'] = 'Bearer $token';
    }
    return all;
  }

  Future<http.Response> _send(
    Future<http.Response> Function(String? token) request, {
    required bool authenticated,
  }) async {
    String? token;
    if (authenticated && tokenStore != null) {
      token = await tokenStore!.readAccessToken();
    }

    late http.Response response;
    try {
      response = await request(token);
    } catch (_) {
      throw NetworkException('Could not reach the server. Check your connection.');
    }

    // One transparent refresh attempt when the access token expired.
    if (authenticated && response.statusCode == 401 && tokenStore != null) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        token = await tokenStore!.readAccessToken();
        try {
          response = await request(token);
        } catch (_) {
          throw NetworkException('Could not reach the server. Check your connection.');
        }
      }
    }
    return response;
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await tokenStore!.readRefreshToken();
    if (refreshToken == null) return false;
    try {
      final response = await _client.post(
        Uri.parse(ApiConstants.refreshToken),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode != 200) {
        await tokenStore!.clear();
        return false;
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
      if (data is! Map<String, dynamic>) return false;
      await tokenStore!.updateAccessToken(data['accessToken'] as String);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns the `data` payload of the ApiResponse envelope; throws on failure.
  Map<String, dynamic> _unwrap(http.Response response) {
    final decoded = _decode(response);
    if (decoded is! Map<String, dynamic>) {
      throw ServerException(
        _plainText(decoded) ?? 'Unexpected response',
        statusCode: response.statusCode,
      );
    }
    final success = decoded['success'] == true;
    if (!success) {
      throw ServerException(
        decoded['message'] as String? ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }
    final data = decoded['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// Decodes a response body, falling back to the raw text when it is not JSON
  /// — the gateway's JWT filter answers `Invalid or expired token` as plain
  /// text, and that must surface as a typed ServerException, not a
  /// FormatException that escapes every layer.
  Object? _decode(http.Response response) {
    final body = utf8.decode(response.bodyBytes, allowMalformed: true);
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  String? _plainText(Object? decoded) {
    if (decoded is! String) return null;
    final trimmed = decoded.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void dispose() => _client.close();
}
