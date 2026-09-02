import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT session in platform secure storage (Keychain /
/// Keystore / encrypted web storage) so login survives app restarts.
class TokenStore {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  TokenStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> save({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> updateAccessToken(String accessToken) =>
      _storage.write(key: _accessTokenKey, value: accessToken);

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
