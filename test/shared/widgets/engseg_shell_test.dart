import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:engseg_mobile/features/auth/model/login_response.dart';
import 'package:engseg_mobile/features/auth/provider/auth_provider.dart';
import 'package:engseg_mobile/shared/widgets/engseg_shell.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._session);

  final LoginResponse? _session;

  @override
  Future<LoginResponse?> build() async => _session;
}

LoginResponse _session(String perfil) => LoginResponse(
      id: 'u1',
      token: 'tok',
      nome: 'Usuario Teste',
      email: 'teste@example.com',
      perfil: perfil,
      isAdmin: false,
    );

Widget _wrap(LoginResponse? session) {
  final router = GoRouter(
    initialLocation: '/feed',
    routes: [
      ShellRoute(
        builder: (_, __, child) => EngSegShell(child: child),
        routes: [
          GoRoute(path: '/feed', builder: (_, __) => const SizedBox()),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authProvider.overrideWith(() => _FakeAuthNotifier(session)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('mostra o FAB de criacao para perfil ENGENHEIRO', (tester) async {
    await tester.pumpWidget(_wrap(_session('ENGENHEIRO')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });

  testWidgets('mostra o FAB de criacao para perfil TECNICO', (tester) async {
    await tester.pumpWidget(_wrap(_session('TECNICO')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });

  testWidgets('esconde o FAB de criacao para perfil EXTERNO', (tester) async {
    await tester.pumpWidget(_wrap(_session('EXTERNO')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_rounded), findsNothing);
  });
}
