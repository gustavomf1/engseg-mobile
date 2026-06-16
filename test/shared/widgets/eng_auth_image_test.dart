import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:engseg_mobile/features/auth/model/login_response.dart';
import 'package:engseg_mobile/features/auth/provider/auth_provider.dart';
import 'package:engseg_mobile/shared/widgets/eng_auth_image.dart';

class MockAuthNotifier extends AsyncNotifier<LoginResponse?>
    with Mock
    implements AuthNotifier {
  @override
  Future<LoginResponse?> build() async => const LoginResponse(
        id: 'u1',
        token: 'tok123',
        nome: 'Test',
        email: 't@t.com',
        perfil: 'ENGENHEIRO',
        isAdmin: false,
      );
}

void main() {
  testWidgets('EngAuthImage renderiza sem crash quando token disponível',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(MockAuthNotifier.new),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: EngAuthImage(url: 'http://localhost/api/evidencias/1/download'),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(EngAuthImage), findsOneWidget);
  });

  testWidgets('EngAuthImage renderiza error widget em rede inacessível',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(MockAuthNotifier.new),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: EngAuthImage(
              url: 'http://localhost/api/evidencias/404/download',
              errorWidget: SizedBox(key: Key('err'), width: 10, height: 10),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(EngAuthImage), findsOneWidget);
  });
}
