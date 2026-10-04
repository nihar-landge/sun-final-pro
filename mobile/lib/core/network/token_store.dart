import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT session in platform secure storage (Keychain /
/// Keystore / encrypted web storage) so login survives app restarts.
/// A single 24h access token — no refresh token.
class TokenStore {
  static const _accessTokenKey = 'access_token';

  final FlutterSecureStorage _storage;

  TokenStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> save({required String accessToken}) =>
      _storage.write(key: _accessTokenKey, value: accessToken);

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: 'refresh_token'); // leftover from earlier builds
  }
}
