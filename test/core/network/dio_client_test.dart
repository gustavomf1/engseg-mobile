import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:engseg_mobile/core/network/dio_client.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockSecureStorage storage;

  setUp(() {
    storage = MockSecureStorage();
  });

  test('buildDio returns Dio with correct baseUrl', () {
    when(() => storage.read(key: 'jwt_token')).thenAnswer((_) async => null);
    final dio = buildDio(storage);
    expect(dio.options.baseUrl, 'http://engseg-api:8080');
    expect(dio.options.connectTimeout, const Duration(seconds: 30));
  });
}
