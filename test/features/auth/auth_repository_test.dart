import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:engseg_mobile/features/auth/model/login_response.dart';
import 'package:engseg_mobile/features/auth/repository/auth_repository_impl.dart';

class MockDio extends Mock implements Dio {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockDio dio;
  late MockSecureStorage storage;
  late AuthRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    dio = MockDio();
    storage = MockSecureStorage();
    repo = AuthRepositoryImpl(dio: dio, storage: storage);
  });

  group('login', () {
    setUp(() {
      when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});
      when(() => dio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/api/auth/login'),
            statusCode: 200,
            data: {
              'id': 'user-uuid',
              'token': 'eyJhbGci.test',
              'nome': 'João Silva',
              'email': 'joao@test.com',
              'perfil': 'ENGENHEIRO',
              'isAdmin': false,
            },
          ));
    });

    test('returns LoginResponse with correct fields', () async {
      final result = await repo.login('joao@test.com', 'senha123');
      expect(result.token, 'eyJhbGci.test');
      expect(result.perfil, 'ENGENHEIRO');
      expect(result.isAdmin, false);
    });

    test('persists jwt_token to secure storage', () async {
      await repo.login('joao@test.com', 'senha123');
      verify(() => storage.write(key: 'jwt_token', value: 'eyJhbGci.test')).called(1);
    });

    test('persists user_session as JSON to secure storage', () async {
      await repo.login('joao@test.com', 'senha123');
      final captured = verify(
        () => storage.write(key: 'user_session', value: captureAny(named: 'value')),
      ).captured;
      final decoded = jsonDecode(captured.first as String) as Map<String, dynamic>;
      expect(decoded['token'], 'eyJhbGci.test');
      expect(decoded['perfil'], 'ENGENHEIRO');
    });
  });

  group('logout', () {
    test('clears all secure storage', () async {
      when(() => storage.deleteAll()).thenAnswer((_) async {});
      await repo.logout();
      verify(() => storage.deleteAll()).called(1);
    });
  });

  group('getSession', () {
    test('returns null when no session stored', () async {
      when(() => storage.read(key: 'user_session')).thenAnswer((_) async => null);
      final result = await repo.getSession();
      expect(result, isNull);
    });

    test('returns LoginResponse from stored session JSON', () async {
      final stored = jsonEncode({
        'id': 'u1',
        'token': 'tok',
        'nome': 'Ana',
        'email': 'ana@test.com',
        'perfil': 'TECNICO',
        'isAdmin': false,
      });
      when(() => storage.read(key: 'user_session')).thenAnswer((_) async => stored);
      final result = await repo.getSession();
      expect(result?.perfil, 'TECNICO');
      expect(result?.nome, 'Ana');
    });
  });
}
