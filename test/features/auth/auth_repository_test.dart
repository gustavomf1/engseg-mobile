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

  test('login persists token and returns LoginResponse', () async {
    when(() => dio.post(
      any(),
      data: any(named: 'data'),
    )).thenAnswer((_) async => Response(
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
    when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});

    final result = await repo.login('joao@test.com', 'senha123');
    expect(result.token, 'eyJhbGci.test');
    expect(result.perfil, 'ENGENHEIRO');
    verify(() => storage.write(key: 'jwt_token', value: 'eyJhbGci.test')).called(1);
  });
}
