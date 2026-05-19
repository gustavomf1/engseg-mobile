import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/core/config/app_config.dart';

void main() {
  test('AppConfig has correct base URLs', () {
    expect(AppConfig.apiBaseUrl, equals('http://engseg-api:8080'));
    expect(AppConfig.bffBaseUrl, equals('http://engseg-mobile-backend:8081'));
  });

  test('AppConfig has correct timeouts', () {
    expect(AppConfig.connectTimeout, equals(const Duration(seconds: 30)));
    expect(AppConfig.receiveTimeout, equals(const Duration(seconds: 60)));
  });
}
