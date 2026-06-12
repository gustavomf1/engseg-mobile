import 'trativa_desvio.dart';

class DesvioDetail {
  final String id;
  final String titulo;
  final String status; // ABERTO | AGUARDANDO_TRATATIVA | AGUARDANDO_APROVACAO | CONCLUIDO
  final String estabelecimentoId;
  final String estabelecimentoNome;
  final String? localizacaoNome;
  final String? descricao;
  final String? orientacaoRealizada;
  final bool regraDeOuro;
  final String dataRegistro;
  final String? responsavelDesvioId;
  final String? responsavelDesvioNome;
  final String? responsavelTratativaId;
  final String? responsavelTratativaNome;
  final String? usuarioCriacaoNome;
  final String? usuarioCriacaoEmail;
  final List<TrativaDesvio> tratativas;
  final List<Map<String, dynamic>> historico;

  const DesvioDetail({
    required this.id,
    required this.titulo,
    required this.status,
    this.estabelecimentoId = '',
    this.estabelecimentoNome = '',
    this.localizacaoNome,
    this.descricao,
    this.orientacaoRealizada,
    this.regraDeOuro = false,
    this.dataRegistro = '',
    this.responsavelDesvioId,
    this.responsavelDesvioNome,
    this.responsavelTratativaId,
    this.responsavelTratativaNome,
    this.usuarioCriacaoNome,
    this.usuarioCriacaoEmail,
    this.tratativas = const [],
    this.historico = const [],
  });

  factory DesvioDetail.fromJson(Map<String, dynamic> j) => DesvioDetail(
        id: j['id'] as String,
        titulo: j['titulo'] as String? ?? '',
        status: j['status'] as String? ?? 'ABERTO',
        estabelecimentoId: j['estabelecimentoId'] as String? ?? '',
        estabelecimentoNome: j['estabelecimentoNome'] as String? ?? '',
        localizacaoNome: j['localizacaoNome'] as String?,
        descricao: j['descricao'] as String?,
        orientacaoRealizada: j['orientacaoRealizada'] as String?,
        regraDeOuro: j['regraDeOuro'] as bool? ?? false,
        dataRegistro: j['dataRegistro'] as String? ?? '',
        responsavelDesvioId: j['responsavelDesvioId'] as String?,
        responsavelDesvioNome: j['responsavelDesvioNome'] as String?,
        responsavelTratativaId: j['responsavelTratativaId'] as String?,
        // chave backend tem typo "Trativa" (DesvioResponse.responsavelTrativaNome)
        responsavelTratativaNome: j['responsavelTrativaNome'] as String?,
        usuarioCriacaoNome: j['usuarioCriacaoNome'] as String?,
        usuarioCriacaoEmail: j['usuarioCriacaoEmail'] as String?,
        tratativas: (j['tratativas'] as List<dynamic>? ?? [])
            .map((e) => TrativaDesvio.fromJson(e as Map<String, dynamic>))
            .toList(),
        historico: (j['historico'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>(),
      );

  int get rodadaAtual {
    final rodadas = tratativas.map((t) => t.rodada).whereType<int>();
    return rodadas.isEmpty ? 0 : rodadas.reduce((a, b) => a > b ? a : b);
  }

  bool get temTratativasPendentesNaoSubmetidas =>
      tratativas.any((t) => t.rodada == null && t.status == 'PENDENTE');
}
