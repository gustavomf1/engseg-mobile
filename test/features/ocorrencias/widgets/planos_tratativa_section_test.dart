import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/features/ocorrencias/model/desvio_detail.dart';
import 'package:engseg_mobile/features/ocorrencias/model/trativa_desvio.dart';
import 'package:engseg_mobile/features/ocorrencias/widgets/planos_tratativa_section.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

DesvioDetail _buildDesvio() => const DesvioDetail(
      id: 'd-1',
      titulo: 'Desvio de teste',
      status: 'AGUARDANDO_APROVACAO',
      tratativas: [
        TrativaDesvio(
          id: 't-1',
          titulo: 'Instalação de guarda-corpo',
          descricao: 'Guarda-corpo instalado no setor',
          status: 'REPROVADO',
          motivoReprovacao: 'Faltou o anexo',
          numero: 1,
          rodada: 1,
        ),
        TrativaDesvio(
          id: 't-2',
          titulo: 'Sinalização da área',
          descricao: 'Placas fixadas',
          status: 'APROVADO',
          numero: 2,
          rodada: 1,
        ),
        TrativaDesvio(
          id: 't-3',
          titulo: 'Treinamento NR-35',
          descricao: 'Treinamento aplicado à equipe',
          status: 'PENDENTE',
          numero: 3,
          rodada: 2,
        ),
      ],
      historico: [
        {
          'tipo': 'TRATATIVA_SUBMETIDA',
          'usuarioNome': 'Tecnico X',
          'dataAcao': '2026-06-11T17:47:59',
        },
        {
          'tipo': 'REPROVADO',
          'usuarioNome': 'Gustavo França',
          'comentario': 'Tratativa 1: Faltou o anexo',
          'dataAcao': '2026-06-12T14:34:03',
        },
        {
          'tipo': 'TRATATIVA_SUBMETIDA',
          'usuarioNome': 'Tecnico X',
          'dataAcao': '2026-06-12T14:59:01',
        },
      ],
    );

void main() {
  testWidgets('Plano reprovado vem recolhido e o plano atual vem expandido',
      (tester) async {
    await tester
        .pumpWidget(_wrap(PlanosTratativaSection(d: _buildDesvio(), token: null)));

    expect(find.text('Plano 1'), findsOneWidget);
    expect(find.text('Plano 2'), findsOneWidget);
    expect(find.text('Reprovado'), findsOneWidget);
    expect(find.text('Em análise'), findsOneWidget);

    // Plano 1 (reprovado) recolhido: motivo não visível, mas aviso de quem
    // reprovou sim, mesmo recolhido.
    expect(find.text('Motivo: Faltou o anexo'), findsNothing);
    expect(find.textContaining('Reprovado por Gustavo França'), findsOneWidget);

    // Plano 2 (rodada atual) expandido por padrão
    expect(find.text('Treinamento NR-35'), findsOneWidget);
  });

  testWidgets('tocar no cabeçalho do plano reprovado expande o conteúdo',
      (tester) async {
    await tester
        .pumpWidget(_wrap(PlanosTratativaSection(d: _buildDesvio(), token: null)));

    await tester.tap(find.text('Plano 1'));
    await tester.pumpAndSettle();

    expect(find.text('Motivo: Faltou o anexo'), findsOneWidget);
    expect(find.text('Sinalização da área'), findsOneWidget);
  });

  testWidgets('sem tratativas mostra mensagem vazia', (tester) async {
    await tester.pumpWidget(_wrap(const PlanosTratativaSection(
      d: DesvioDetail(id: 'd-2', titulo: 'X', status: 'ABERTO'),
      token: null,
    )));

    expect(find.text('Nenhuma tratativa ainda'), findsOneWidget);
  });
}
