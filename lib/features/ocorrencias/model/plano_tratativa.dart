import 'trativa_desvio.dart';

enum ResultadoPlano { reprovado, aprovado, emAnalise }

/// Agrupamento de [TrativaDesvio] por rodada ("Plano"), casado com as
/// entradas de submissão/resultado do histórico do Desvio.
class Plano {
  final int rodada;
  final List<TrativaDesvio> tratativas;
  final ResultadoPlano resultado;
  final String? dataSubmissao;
  final String? dataResultado;
  final String? revisorNome;
  final String? comentario;

  const Plano({
    required this.rodada,
    required this.tratativas,
    required this.resultado,
    this.dataSubmissao,
    this.dataResultado,
    this.revisorNome,
    this.comentario,
  });
}

/// Assume que `historico` é um log cronológico em que cada rodada gera no
/// máximo uma entrada `TRATATIVA_SUBMETIDA` e, depois, no máximo uma entrada
/// de resultado (`APROVADO`/`REPROVADO`) — por isso o pareamento por índice
/// entre rodadas ordenadas e entradas filtradas do histórico.
List<Plano> buildPlanos(
  List<TrativaDesvio> tratativas,
  List<Map<String, dynamic>> historico,
) {
  final byRodada = <int, List<TrativaDesvio>>{};
  for (final t in tratativas) {
    byRodada.putIfAbsent(t.rodada, () => []).add(t);
  }

  final submissoes = <Map<String, dynamic>>[];
  final resultados = <Map<String, dynamic>>[];
  for (final h in historico) {
    final tipo = h['tipo'] as String?;
    if (tipo == 'TRATATIVA_SUBMETIDA') {
      submissoes.add(h);
    } else if (tipo == 'REPROVADO' || tipo == 'APROVADO') {
      resultados.add(h);
    }
  }

  final rodadas = byRodada.keys.toList()..sort();
  return [
    for (var i = 0; i < rodadas.length; i++)
      _buildPlano(
        rodadas[i],
        byRodada[rodadas[i]]!..sort((a, b) => a.numero.compareTo(b.numero)),
        i < submissoes.length ? submissoes[i] : null,
        i < resultados.length ? resultados[i] : null,
      ),
  ];
}

Plano _buildPlano(
  int rodada,
  List<TrativaDesvio> tratativas,
  Map<String, dynamic>? submissao,
  Map<String, dynamic>? resultadoHist,
) {
  final temReprovada = tratativas.any((t) => t.status == 'REPROVADO');
  final todosAprovados = tratativas.every((t) => t.status == 'APROVADO');
  final resultado = resultadoHist != null
      ? (resultadoHist['tipo'] == 'REPROVADO'
          ? ResultadoPlano.reprovado
          : ResultadoPlano.aprovado)
      : (temReprovada
          ? ResultadoPlano.reprovado
          : todosAprovados
              ? ResultadoPlano.aprovado
              : ResultadoPlano.emAnalise);

  return Plano(
    rodada: rodada,
    tratativas: tratativas,
    resultado: resultado,
    dataSubmissao: submissao?['dataAcao'] as String?,
    dataResultado: resultadoHist?['dataAcao'] as String?,
    revisorNome: resultadoHist?['usuarioNome'] as String?,
    comentario: resultadoHist?['comentario'] as String?,
  );
}
