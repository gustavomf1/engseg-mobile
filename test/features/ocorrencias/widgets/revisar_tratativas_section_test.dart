import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/features/ocorrencias/model/desvio_detail.dart';
import 'package:engseg_mobile/features/ocorrencias/model/trativa_desvio.dart';
import 'package:engseg_mobile/features/ocorrencias/widgets/revisar_tratativas_section.dart';
import 'package:mocktail/mocktail.dart';
import 'package:engseg_mobile/features/ocorrencias/model/desvio_action_requests.dart';
import 'package:engseg_mobile/features/ocorrencias/repository/desvio_repository.dart';
import 'package:engseg_mobile/features/ocorrencias/repository/desvio_repository_impl.dart';

class MockDesvioRepository extends Mock implements DesvioRepository {}

Widget _wrapWithRepo(Widget child, DesvioRepository repo) => ProviderScope(
      overrides: [desvioRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

DesvioDetail _buildDesvio() => const DesvioDetail(
      id: 'd-1',
      titulo: 'Desvio de teste',
      status: 'AGUARDANDO_APROVACAO',
      tratativas: [
        TrativaDesvio(
          id: 't-1',
          titulo: 'Tratativa 1',
          descricao: 'Descrição 1',
          status: 'PENDENTE',
          numero: 1,
          rodada: 1,
        ),
        TrativaDesvio(
          id: 't-2',
          titulo: 'Tratativa 2',
          descricao: 'Descrição 2',
          status: 'PENDENTE',
          numero: 2,
          rodada: 1,
        ),
      ],
    );

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(const AprovarDesvioRequest());
    registerFallbackValue(const ReprovarTrativasDesvioRequest(itens: []));
  });

  testWidgets('estado inicial mostra comentário opcional e botão Aprovar Todas',
      (tester) async {
    await tester.pumpWidget(_wrap(RevisarTratativasSection(
      d: _buildDesvio(),
      token: null,
      runAction: (action) => action(),
    )));

    expect(find.text('REVISAR TRATATIVAS'), findsOneWidget);
    expect(find.text('Tratativa 1'), findsOneWidget);
    expect(find.text('Tratativa 2'), findsOneWidget);
    expect(find.text('Aprovar Todas'), findsOneWidget);
    expect(find.text('Observações sobre a aprovação...'), findsOneWidget);
    expect(find.text('Aprovar'), findsNWidgets(2));
    expect(find.text('Reprovar'), findsNWidgets(2));
    expect(find.text('Motivo da reprovação (obrigatório)'), findsNothing);
  });

  testWidgets('marcar reprovar exibe motivo obrigatório e muda o botão',
      (tester) async {
    await tester.pumpWidget(_wrap(RevisarTratativasSection(
      d: _buildDesvio(),
      token: null,
      runAction: (action) => action(),
    )));

    await tester.tap(find.text('Reprovar').first);
    await tester.pump();

    expect(find.text('Motivo da reprovação (obrigatório)'), findsOneWidget);
    expect(find.text('Observações sobre a aprovação...'), findsNothing);
    expect(find.text('Reprovar 1 tratativa(s)'), findsOneWidget);
    expect(find.text('Aprovar Todas'), findsNothing);
  });

  testWidgets(
      'reprovar com motivo vazio mostra erro e não chama o repositório',
      (tester) async {
    final repo = MockDesvioRepository();
    when(() => repo.reprovar(any(), any())).thenAnswer((_) async {});

    await tester.pumpWidget(_wrapWithRepo(
      RevisarTratativasSection(
        d: _buildDesvio(),
        token: null,
        runAction: (action) => action(),
      ),
      repo,
    ));

    await tester.tap(find.text('Reprovar').first);
    await tester.pump();

    await tester.tap(find.text('Reprovar 1 tratativa(s)'));
    await tester.pumpAndSettle();

    expect(
      find.text(
          'Preencha o motivo de todas as tratativas marcadas para reprovação.'),
      findsOneWidget,
    );
    verifyNever(() => repo.reprovar(any(), any()));
  });

  testWidgets(
      'reprovar com motivo preenchido chama o repositório com o item marcado',
      (tester) async {
    final repo = MockDesvioRepository();
    when(() => repo.reprovar(any(), any())).thenAnswer((_) async {});

    await tester.pumpWidget(_wrapWithRepo(
      RevisarTratativasSection(
        d: _buildDesvio(),
        token: null,
        runAction: (action) => action(),
      ),
      repo,
    ));

    await tester.tap(find.text('Reprovar').first);
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Faltou anexar o laudo');
    await tester.tap(find.text('Reprovar 1 tratativa(s)'));
    await tester.pumpAndSettle();

    final captured =
        verify(() => repo.reprovar('d-1', captureAny())).captured;
    final request = captured.single as ReprovarTrativasDesvioRequest;
    expect(request.itens, hasLength(1));
    expect(request.itens.first.trativaId, 't-1');
    expect(request.itens.first.motivo, 'Faltou anexar o laudo');
  });

  testWidgets('aprovar todas chama o repositório com o comentário informado',
      (tester) async {
    final repo = MockDesvioRepository();
    when(() => repo.aprovar(any(), any())).thenAnswer((_) async {});

    await tester.pumpWidget(_wrapWithRepo(
      RevisarTratativasSection(
        d: _buildDesvio(),
        token: null,
        runAction: (action) => action(),
      ),
      repo,
    ));

    await tester.enterText(find.byType(TextField), 'Tudo certo, parabéns');
    await tester.tap(find.text('Aprovar Todas'));
    await tester.pumpAndSettle();

    final captured = verify(() => repo.aprovar('d-1', captureAny())).captured;
    final request = captured.single as AprovarDesvioRequest;
    expect(request.toJson()['comentario'], 'Tudo certo, parabéns');
  });

  testWidgets(
      'alternar de Reprovar para Aprovar no mesmo item volta ao estado neutro',
      (tester) async {
    await tester.pumpWidget(_wrap(RevisarTratativasSection(
      d: _buildDesvio(),
      token: null,
      runAction: (action) => action(),
    )));

    await tester.tap(find.text('Reprovar').first);
    await tester.pump();

    expect(find.text('Motivo da reprovação (obrigatório)'), findsOneWidget);
    expect(find.text('Reprovar 1 tratativa(s)'), findsOneWidget);

    await tester.tap(find.text('Aprovar').first);
    await tester.pump();

    expect(find.text('Motivo da reprovação (obrigatório)'), findsNothing);
    expect(find.text('Aprovar Todas'), findsOneWidget);
  });
}
