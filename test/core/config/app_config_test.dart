import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/core/config/app_config.dart';

void main() {
  test('AppConfig has correct base URLs', () {
    expect(AppConfig.apiBaseUrl, contains('8080'));
    expect(AppConfig.bffBaseUrl, contains('8081'));
  });
}
