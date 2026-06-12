import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/features/ocorrencias/model/plano_tratativa.dart';
import 'package:engseg_mobile/features/ocorrencias/model/trativa_desvio.dart';

List<TrativaDesvio> _tratativas() => const [
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
    ];

List<Map<String, dynamic>> _historico() => [
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
    ];

void main() {
  test('agrupa por rodada e casa submissão/resultado por índice', () {
    final planos = buildPlanos(_tratativas(), _historico());

    expect(planos, hasLength(2));

    final plano1 = planos[0];
    expect(plano1.rodada, 1);
    expect(plano1.tratativas.map((t) => t.numero), [1, 2]);
    expect(plano1.resultado, ResultadoPlano.reprovado);
    expect(plano1.dataSubmissao, '2026-06-11T17:47:59');
    expect(plano1.dataResultado, '2026-06-12T14:34:03');
    expect(plano1.revisorNome, 'Gustavo França');
    expect(plano1.comentario, 'Tratativa 1: Faltou o anexo');

    final plano2 = planos[1];
    expect(plano2.rodada, 2);
    expect(plano2.tratativas.map((t) => t.numero), [3]);
    expect(plano2.resultado, ResultadoPlano.emAnalise);
    expect(plano2.dataSubmissao, '2026-06-12T14:59:01');
    expect(plano2.dataResultado, isNull);
    expect(plano2.revisorNome, isNull);
  });

  test('sem historico, todas aprovadas resulta em plano aprovado', () {
    final planos = buildPlanos(
      const [
        TrativaDesvio(
          id: 't-1',
          titulo: 'Item',
          descricao: 'Desc',
          status: 'APROVADO',
          numero: 1,
          rodada: 1,
        ),
      ],
      [],
    );

    expect(planos, hasLength(1));
    expect(planos.single.resultado, ResultadoPlano.aprovado);
  });

  test('sem tratativas retorna lista vazia', () {
    expect(buildPlanos(const [], const []), isEmpty);
  });
}
