import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/core/router/route_guards.dart';

void main() {
  group('isExternoBlockedRoute', () {
    test('bloqueia acesso direto a /camera', () {
      expect(isExternoBlockedRoute('/camera'), isTrue);
    });

    test('bloqueia acesso direto a /wizard/:tipo', () {
      expect(isExternoBlockedRoute('/wizard/nc'), isTrue);
      expect(isExternoBlockedRoute('/wizard/desvio'), isTrue);
    });

    test('nao bloqueia rotas normais do feed', () {
      expect(isExternoBlockedRoute('/feed'), isFalse);
      expect(isExternoBlockedRoute('/desvios'), isFalse);
      expect(isExternoBlockedRoute('/profile'), isFalse);
    });
  });
}
