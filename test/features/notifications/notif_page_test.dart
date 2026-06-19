import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:engseg_mobile/features/notifications/notif_page.dart';
import 'package:engseg_mobile/features/notifications/model/notificacao_item.dart';
import 'package:engseg_mobile/features/notifications/repository/notificacao_repository_impl.dart';

final _router = GoRouter(routes: [
  GoRoute(path: '/', builder: (_, __) => const NotifPage()),
  GoRoute(path: '/oc/:id', builder: (_, __) => const SizedBox()),
]);

Widget _wrap(List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(routerConfig: _router),
    );

final _item = NotificacaoItem(
  id: 'notif-1',
  ncId: 'nc-1',
  tipo: 'NC_ATIVADA',
  titulo: 'EngSeg — NC Teste',
  corpo: 'corpo do push',
  lida: false,
  criadoEm: DateTime(2026, 6, 19, 10, 0),
);

void main() {
  testWidgets('notif page mostra lista vinda do provider', (tester) async {
    await tester.pumpWidget(_wrap([
      notificacoesProvider.overrideWith((ref) async => [_item]),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('EngSeg — NC Teste'), findsOneWidget);
    expect(find.text('corpo do push'), findsOneWidget);
  });

  testWidgets('notif page mostra empty state quando lista vazia', (tester) async {
    await tester.pumpWidget(_wrap([
      notificacoesProvider.overrideWith((ref) async => []),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma notificação por aqui'), findsOneWidget);
  });
}
