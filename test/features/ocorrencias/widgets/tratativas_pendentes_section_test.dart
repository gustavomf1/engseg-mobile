import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/features/ocorrencias/model/desvio_detail.dart';
import 'package:engseg_mobile/features/ocorrencias/model/trativa_desvio.dart';
import 'package:engseg_mobile/features/ocorrencias/widgets/tratativas_pendentes_section.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets(
      'mostra tratativas com rodada null como plano atual pendente',
      (tester) async {
    const d = DesvioDetail(
      id: 'd-1',
      titulo: 'Desvio de teste',
      status: 'AGUARDANDO_TRATATIVA',
      tratativas: [
        TrativaDesvio(
          id: 't-1',
          titulo: 'Treinamento NR-35',
          descricao: 'Treinamento aplicado à equipe',
          status: 'REPROVADO',
          motivoReprovacao: 'Faltou o anexo',
          numero: 1,
          rodada: 1,
        ),
        TrativaDesvio(
          id: 't-2',
          titulo: 'olha',
          descricao: 'Nova tratativa ainda em elaboração',
          status: 'PENDENTE',
          numero: 2,
          rodada: null,
        ),
      ],
    );

    await tester.pumpWidget(_wrap(const TratativasPendentesSection(d: d, token: null)));

    expect(find.textContaining('TRATATIVAS DO PLANO ATUAL'), findsOneWidget);
    expect(find.text('olha'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);
    // A tratativa da rodada já submetida (1) não deve aparecer aqui.
    expect(find.text('Treinamento NR-35'), findsNothing);
  });

  testWidgets('sem tratativas pendentes não renderiza nada', (tester) async {
    const d = DesvioDetail(
      id: 'd-2',
      titulo: 'Desvio de teste',
      status: 'AGUARDANDO_TRATATIVA',
      tratativas: [
        TrativaDesvio(
          id: 't-1',
          titulo: 'Treinamento NR-35',
          descricao: 'Treinamento aplicado à equipe',
          status: 'APROVADO',
          numero: 1,
          rodada: 1,
        ),
      ],
    );

    await tester.pumpWidget(_wrap(const TratativasPendentesSection(d: d, token: null)));

    expect(find.textContaining('TRATATIVAS DO PLANO ATUAL'), findsNothing);
    expect(find.byType(SizedBox), findsWidgets);
  });
}
