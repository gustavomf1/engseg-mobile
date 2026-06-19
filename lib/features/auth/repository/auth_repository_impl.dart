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
    if (loginResponse.refreshToken != null) {
      await storage.write(key: 'refresh_token', value: loginResponse.refreshToken);
    }
    await storage.write(
      key: 'user_session',
      value: jsonEncode(loginResponse.toJson()),
    );
    return loginResponse;
  }

  @override
  Future<void> logout() async {
    // Revoga o refresh token no servidor (best-effort).
    final refreshToken = await storage.read(key: 'refresh_token');
    if (refreshToken != null) {
      try {
        await dio.post('/api/auth/logout', data: {'refreshToken': refreshToken});
      } catch (_) {
        // ignore
      }
    }
    await storage.deleteAll();
  }

  @override
  Future<LoginResponse?> getSession() async {
    final sessionJson = await storage.read(key: 'user_session');
    if (sessionJson == null) return null;

    final token = await storage.read(key: 'jwt_token');

    // Access token curto (M2): se expirou, tenta renovar com o refresh token
    // antes de descartar a sessão (senão o app deslogaria a cada 15 min).
    if (token == null || _isTokenExpired(token)) {
      final renovado = await _tentarRenovar();
      if (!renovado) {
        await storage.deleteAll();
        return null;
      }
    }

    return LoginResponse.fromJson(
      jsonDecode(sessionJson) as Map<String, dynamic>,
    );
  }

  Future<bool> _tentarRenovar() async {
    final refreshToken = await storage.read(key: 'refresh_token');
    if (refreshToken == null) return false;
    try {
      final raw = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
      final resp = await raw.post(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final newToken = resp.data['token'] as String?;
      final newRefresh = resp.data['refreshToken'] as String?;
      if (newToken == null) return false;
      await storage.write(key: 'jwt_token', value: newToken);
      if (newRefresh != null) {
        await storage.write(key: 'refresh_token', value: newRefresh);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final exp = payload['exp'] as int?;
      if (exp == null) return false;
      return DateTime.now().isAfter(
        DateTime.fromMillisecondsSinceEpoch(exp * 1000),
      );
    } catch (_) {
      return true;
    }
  }
}
