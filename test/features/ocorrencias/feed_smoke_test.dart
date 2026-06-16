import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:engseg_mobile/features/auth/model/login_response.dart';
import 'package:engseg_mobile/features/auth/model/workspace_state.dart';
import 'package:engseg_mobile/features/auth/provider/auth_provider.dart';
import 'package:engseg_mobile/features/ocorrencias/model/ocorrencia_summary.dart';
import 'package:engseg_mobile/features/ocorrencias/model/empresa.dart';
import 'package:engseg_mobile/features/ocorrencias/model/estabelecimento.dart';
import 'package:engseg_mobile/features/ocorrencias/repository/ocorrencias_repository_impl.dart';
import 'package:engseg_mobile/features/ocorrencias/feed_page.dart';
import 'package:engseg_mobile/shared/widgets/eng_cover_card.dart';
import 'package:engseg_mobile/shared/widgets/eng_skeleton.dart';

class MockAuthNotifier extends AsyncNotifier<LoginResponse?>
    with Mock
    implements AuthNotifier {
  @override
  Future<LoginResponse?> build() async => const LoginResponse(
        id: 'u1', token: 'tok', nome: 'T', email: 't@t.com',
        perfil: 'ENGENHEIRO', isAdmin: false,
      );
}

final _ws = WorkspaceState(
  empresa: const Empresa(id: 'e-1', nome: 'Empresa'),
  estabelecimento: const Estabelecimento(id: 'ws-1', nome: 'WS'),
  empresaFilha: const Empresa(id: 'ef-1', nome: 'EmpFilha'),
);

final _router = GoRouter(routes: [
  GoRoute(path: '/', builder: (_, __) => const FeedPage()),
  GoRoute(path: '/oc/:id', builder: (_, __) => const SizedBox()),
]);

Widget _wrap(List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(routerConfig: _router),
    );

const _nc = OcorrenciaSummary(
  tipo: 'NAO_CONFORMIDADE',
  id: 'nc-1',
  titulo: 'NC Teste',
  status: 'ABERTA',
  estabelecimentoNome: 'Obra',
  dataRegistro: '2026-06-01',
  nivelRisco: 'ALTO',
);

void main() {
  testWidgets('feed NC mostra skeleton no loading', (tester) async {
    final completer = Completer<List<OcorrenciaSummary>>();
    await tester.pumpWidget(_wrap([
      authProvider.overrideWith(MockAuthNotifier.new),
      workspaceProvider.overrideWith((ref) => _ws),
      ocorrenciasProvider.overrideWith((ref, _) => completer.future),
    ]));
    await tester.pump(Duration.zero); // fire flutter_animate startup timers
    expect(find.byType(CoverCardSkeleton), findsWidgets);
    completer.complete([]); // resolve provider → skeletons replaced → animation disposed
    await tester.pumpAndSettle();
  });

  testWidgets('feed NC mostra EngCoverCard com dados', (tester) async {
    await tester.pumpWidget(_wrap([
      authProvider.overrideWith(MockAuthNotifier.new),
      workspaceProvider.overrideWith((ref) => _ws),
      ocorrenciasProvider.overrideWith((ref, _) async => [_nc]),
    ]));
    await tester.pumpAndSettle();
    expect(find.byType(EngCoverCard), findsOneWidget);
    expect(find.text('NC Teste'), findsOneWidget);
  });

  testWidgets('feed NC mostra empty state quando lista vazia', (tester) async {
    await tester.pumpWidget(_wrap([
      authProvider.overrideWith(MockAuthNotifier.new),
      workspaceProvider.overrideWith((ref) => _ws),
      ocorrenciasProvider.overrideWith((ref, _) async => []),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma NC encontrada'), findsOneWidget);
  });

  testWidgets('feed NC mostra error state em falha de rede', (tester) async {
    await tester.pumpWidget(_wrap([
      authProvider.overrideWith(MockAuthNotifier.new),
      workspaceProvider.overrideWith((ref) => _ws),
      ocorrenciasProvider.overrideWith(
          (ref, _) async => throw Exception('Sem rede')),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('Erro ao carregar'), findsOneWidget);
  });
}
