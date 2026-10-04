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
  Future<void> register({required String name, required String email, required String password}) async {
    try {
      await remoteDataSource.register(name: name, email: email, password: password);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    }
  }

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    try {
      final data = await remoteDataSource.login(email: email, password: password);
      final session = _sessionFrom(data, fallbackEmail: email);
      await tokenStore.save(accessToken: session.accessToken);
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
      final data = await remoteDataSource.me();
      final userJson = data['user'] ?? data;
      return AuthSession(
        accessToken: accessToken,
        expiresIn: 24 * 60 * 60,
        user: userJson is Map<String, dynamic>
            ? UserModel.fromJson(userJson).toEntity()
            : const User(id: 0, email: '', name: '', role: 'CITIZEN'),
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
    // Stateless JWT: the server keeps no session; clearing local storage is all.
    await tokenStore.clear();
  }

  AuthSession _sessionFrom(Map<String, dynamic> data, {required String fallbackEmail}) {
    final userJson = data['user'];
    final user = userJson is Map<String, dynamic>
        ? UserModel.fromJson(userJson).toEntity()
        : User(
            id: (data['userId'] as num?)?.toInt() ?? 0,
            email: fallbackEmail,
            name: 'Citizen',
            role: 'CITIZEN');
    return AuthSession(
      accessToken: data['accessToken'] as String,
      expiresIn: (data['expiresIn'] as num? ?? 24 * 60 * 60).toInt(),
      user: user,
    );
  }
}
