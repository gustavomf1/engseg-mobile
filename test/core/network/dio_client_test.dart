import 'package:dio/dio.dart';
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

  test('buildDio returns Dio with correct baseUrl and connectTimeout', () {
    when(() => storage.read(key: 'jwt_token')).thenAnswer((_) async => null);
    final dio = buildDio(storage);
    expect(dio.options.baseUrl, 'http://engseg-api:8080');
    expect(dio.options.connectTimeout, const Duration(seconds: 30));
  });

  test('buildDio sets receiveTimeout to 60 seconds', () {
    when(() => storage.read(key: 'jwt_token')).thenAnswer((_) async => null);
    final dio = buildDio(storage);
    expect(dio.options.receiveTimeout, const Duration(seconds: 60));
  });

  test('buildDio adds Content-Type application/json header', () {
    when(() => storage.read(key: 'jwt_token')).thenAnswer((_) async => null);
    final dio = buildDio(storage);
    expect(dio.options.headers['Content-Type'], 'application/json');
  });

  test('buildDio registers custom JWT interceptor', () {
    when(() => storage.read(key: 'jwt_token')).thenAnswer((_) async => null);
    final dio = buildDio(storage);
    // Dio automatically adds ImplyContentTypeInterceptor, so we expect at least 1
    expect(dio.interceptors.length, greaterThanOrEqualTo(1));
    // Find the InterceptorsWrapper (our custom JWT interceptor)
    final hasJwtInterceptor = dio.interceptors
        .any((interceptor) => interceptor is InterceptorsWrapper);
    expect(hasJwtInterceptor, isTrue);
  });

  test('JWT interceptor is of type InterceptorsWrapper', () {
    when(() => storage.read(key: 'jwt_token')).thenAnswer((_) async => null);
    final dio = buildDio(storage);

    final interceptors =
        dio.interceptors.whereType<InterceptorsWrapper>().toList();
    expect(interceptors.isNotEmpty, isTrue);
    expect(interceptors.length, equals(1));
  });

  test('buildDio configures all required timeout settings', () {
    when(() => storage.read(key: 'jwt_token')).thenAnswer((_) async => null);
    final dio = buildDio(storage);

    expect(dio.options.baseUrl, isNotEmpty);
    expect(dio.options.connectTimeout, isNotNull);
    expect(dio.options.receiveTimeout, isNotNull);
    expect(dio.options.headers['Content-Type'], 'application/json');
  });

  test('buildDio initializes with Content-Type header', () {
    when(() => storage.read(key: 'jwt_token')).thenAnswer((_) async => null);
    final dio = buildDio(storage);

    expect(dio.options.headers.isEmpty, isFalse);
    expect(dio.options.headers.containsKey('Content-Type'), isTrue);
  });

  test('buildDio baseUrl matches expected API endpoint', () {
    when(() => storage.read(key: 'jwt_token')).thenAnswer((_) async => null);
    final dio = buildDio(storage);

    expect(dio.options.baseUrl, contains('engseg-api'));
    expect(dio.options.baseUrl, contains('8080'));
  });
}
