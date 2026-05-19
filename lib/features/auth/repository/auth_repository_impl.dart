import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../model/login_response.dart';
import 'auth_repository.dart';
import '../../../core/network/dio_client.dart';

final _storageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    dio: ref.watch(dioProvider),
    storage: ref.watch(_storageProvider),
  );
});

class AuthRepositoryImpl implements AuthRepository {
  final Dio dio;
  final FlutterSecureStorage storage;

  AuthRepositoryImpl({required this.dio, required this.storage});

  @override
  Future<LoginResponse> login(String email, String senha) async {
    final response = await dio.post(
      '/api/auth/login',
      data: {'email': email, 'senha': senha},
    );
    final loginResponse = LoginResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
    await storage.write(key: 'jwt_token', value: loginResponse.token);
    await storage.write(
      key: 'user_session',
      value: jsonEncode(loginResponse.toJson()),
    );
    return loginResponse;
  }

  @override
  Future<void> logout() async {
    await storage.deleteAll();
  }

  @override
  Future<LoginResponse?> getSession() async {
    final sessionJson = await storage.read(key: 'user_session');
    if (sessionJson == null) return null;
    return LoginResponse.fromJson(
      jsonDecode(sessionJson) as Map<String, dynamic>,
    );
  }
}
