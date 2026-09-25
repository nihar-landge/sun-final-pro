import 'package:feedback_app/core/errors/exceptions.dart';
import 'package:feedback_app/core/errors/failures.dart';
import 'package:feedback_app/core/network/token_store.dart';
import 'package:feedback_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:feedback_app/features/auth/data/models/user_model.dart';
import 'package:feedback_app/features/auth/domain/entities/user.dart';
import 'package:feedback_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final TokenStore tokenStore;

  AuthRepositoryImpl(this.remoteDataSource, this.tokenStore);

  @override
  Future<String?> sendOtp(String phone) async {
    try {
      return await remoteDataSource.sendOtp(phone);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    }
  }

  @override
  Future<AuthSession> verifyOtp({
    required String phone,
    required String code,
    String? name,
  }) async {
    try {
      final data = await remoteDataSource.verifyOtp(phone: phone, code: code, name: name);
      final session = _sessionFrom(data, fallbackPhone: phone, fallbackName: name);
      await tokenStore.save(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      return session;
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    }
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final accessToken = await tokenStore.readAccessToken();
    if (accessToken == null) return null;
    try {
      // A 401 here is auto-refreshed by the ApiClient before this throws.
      final data = await remoteDataSource.me();
      final userJson = data['user'] ?? data;
      return AuthSession(
        accessToken: accessToken,
        refreshToken: await tokenStore.readRefreshToken() ?? '',
        expiresIn: 900,
        user: userJson is Map<String, dynamic>
            ? UserModel.fromJson(userJson).toEntity()
            : const User(id: 0, phone: '', name: '', role: 'CITIZEN'),
      );
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        await tokenStore.clear();
        return null;
      }
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    }
  }

  @override
  Future<void> logout() async {
    final refreshToken = await tokenStore.readRefreshToken();
    if (refreshToken != null) {
      try {
        await remoteDataSource.logout(refreshToken);
      } on ServerException catch (_) {
        // Backend revocation is best-effort; local session is cleared regardless.
      } on NetworkException catch (_) {
        // Offline logout still clears the local session.
      }
    }
    await tokenStore.clear();
  }

  AuthSession _sessionFrom(Map<String, dynamic> data,
      {required String fallbackPhone, String? fallbackName}) {
    final userJson = data['user'];
    final user = userJson is Map<String, dynamic>
        ? UserModel.fromJson(userJson).toEntity()
        : User(
            id: (data['userId'] as num?)?.toInt() ?? 0,
            phone: fallbackPhone,
            name: fallbackName ?? 'Citizen',
            role: 'CITIZEN');
    return AuthSession(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      expiresIn: (data['expiresIn'] as num? ?? 900).toInt(),
      user: user,
    );
  }
}
