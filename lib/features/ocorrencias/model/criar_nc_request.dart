class CriarNcRequest {
  final String estabelecimentoId;
  final String titulo;
  final String? descricao;
  final int severidade;
  final int probabilidade;
  final bool regraDeOuro;
  final bool reincidencia;
  final String? localizacaoId;
  final String? responsavelNcId;
  final String? responsavelTrativaId;
  final List<String> normaIds;
  final List<String> emailsManuais;
  final List<String> emailsPadraoExcluidos;

  const CriarNcRequest({
    required this.estabelecimentoId,
    required this.titulo,
    this.descricao,
    required this.severidade,
    required this.probabilidade,
    this.regraDeOuro = false,
    this.reincidencia = false,
    this.localizacaoId,
    this.responsavelNcId,
    this.responsavelTrativaId,
    this.normaIds = const [],
    this.emailsManuais = const [],
    this.emailsPadraoExcluidos = const [],
  });

  Map<String, dynamic> toJson() => {
        'estabelecimentoId': estabelecimentoId,
        'titulo': titulo,
        if (descricao != null) 'descricao': descricao,
        'severidade': severidade,
        'probabilidade': probabilidade,
        'regraDeOuro': regraDeOuro,
        'reincidencia': reincidencia,
        if (localizacaoId != null) 'localizacaoId': localizacaoId,
        if (responsavelNcId != null) 'responsavelNcId': responsavelNcId,
        if (responsavelTrativaId != null) 'responsavelTrativaId': responsavelTrativaId,
        'normaIds': normaIds,
        'emailsManuais': emailsManuais,
        'emailsPadraoExcluidos': emailsPadraoExcluidos,
      };
}
