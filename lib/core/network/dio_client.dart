import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import 'auth_reset.dart';

final _secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(_secureStorageProvider);
  return buildDio(storage);
});

/// Dio para o BFF (porta 8081). Também envia Bearer e renova em 401 (C3 + M2).
final bffDioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(_secureStorageProvider);
  return buildBffDio(storage);
});

// Garante um único refresh concorrente (single-flight).
Future<String?>? _refreshInFlight;

bool _isAuthPath(String path) =>
    path.contains('/api/auth/login') ||
    path.contains('/api/auth/refresh') ||
    path.contains('/api/auth/logout');

Future<String?> _refreshToken(FlutterSecureStorage storage) async {
  final refreshToken = await storage.read(key: 'refresh_token');
  if (refreshToken == null) return null;
  try {
    // Refresh sempre na API (apiBaseUrl), mesmo para clientes do BFF.
    final raw = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
    final resp = await raw.post(
      '/api/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final newToken = resp.data['token'] as String?;
    final newRefresh = resp.data['refreshToken'] as String?;
    if (newToken == null) return null;
    await storage.write(key: 'jwt_token', value: newToken);
    if (newRefresh != null) {
      await storage.write(key: 'refresh_token', value: newRefresh);
    }
    return newToken;
  } catch (_) {
    return null;
  }
}

/// Interceptor compartilhado: anexa o Bearer e, em 401, renova o token e repete.
InterceptorsWrapper _authRefreshInterceptor(FlutterSecureStorage storage) {
  return InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.read(key: 'jwt_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      final status = error.response?.statusCode;
      final path = error.requestOptions.path;

      if (status == 401 && !_isAuthPath(path)) {
        _refreshInFlight ??= _refreshToken(storage);
        final newToken = await _refreshInFlight;
        _refreshInFlight = null;

        if (newToken != null) {
          try {
            final req = error.requestOptions;
            req.headers['Authorization'] = 'Bearer $newToken';
            final raw = Dio(
              BaseOptions(
                baseUrl: req.baseUrl,
                connectTimeout: AppConfig.connectTimeout,
                receiveTimeout: AppConfig.receiveTimeout,
              ),
            );
            final clone = await raw.fetch(req);
            return handler.resolve(clone);
          } catch (_) {
            // cai para o logout abaixo
          }
        }

        await storage.deleteAll();
        triggerForceLogout();
        handler.resolve(
          Response(requestOptions: error.requestOptions, statusCode: 200, data: null),
        );
        return;
      }
      handler.next(error);
    },
  );
}

Dio buildDio(FlutterSecureStorage storage) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.add(_authRefreshInterceptor(storage));
  return dio;
}

Dio buildBffDio(FlutterSecureStorage storage) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.bffBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.add(_authRefreshInterceptor(storage));
  return dio;
}
