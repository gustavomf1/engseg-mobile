class CriarNcRequest {
  final String estabelecimentoId;
  final String titulo;
  final String? descricao;
  final int severidade;
  final int probabilidade;
  final bool regraDeOuro;
  final bool reincidencia;
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
        'normaIds': normaIds,
        'emailsManuais': emailsManuais,
        'emailsPadraoExcluidos': emailsPadraoExcluidos,
      };
}
