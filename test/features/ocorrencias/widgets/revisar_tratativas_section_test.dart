import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/features/ocorrencias/model/desvio_detail.dart';
import 'package:engseg_mobile/features/ocorrencias/model/trativa_desvio.dart';
import 'package:engseg_mobile/features/ocorrencias/widgets/revisar_tratativas_section.dart';

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
    expect(find.byType(Checkbox), findsNWidgets(2));
    expect(find.text('Motivo da reprovação (obrigatório)'), findsNothing);
  });

  testWidgets('marcar reprovar exibe motivo obrigatório e muda o botão',
      (tester) async {
    await tester.pumpWidget(_wrap(RevisarTratativasSection(
      d: _buildDesvio(),
      token: null,
      runAction: (action) => action(),
    )));

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    expect(find.text('Motivo da reprovação (obrigatório)'), findsOneWidget);
    expect(find.text('Observações sobre a aprovação...'), findsNothing);
    expect(find.text('Reprovar 1 tratativa(s)'), findsOneWidget);
    expect(find.text('Aprovar Todas'), findsNothing);
  });
}
