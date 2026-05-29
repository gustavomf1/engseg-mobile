class CriarDesvioRequest {
  final String estabelecimentoId;
  final String titulo;
  final String? descricao;
  final String? localizacaoId;
  final String? orientacaoRealizada;
  final bool regraDeOuro;
  final String? responsavelDesvioId;
  final String? responsavelTratativaId;
  final List<String> emailsManuais;
  final List<String> emailsPadraoExcluidos;

  const CriarDesvioRequest({
    required this.estabelecimentoId,
    required this.titulo,
    this.descricao,
    this.localizacaoId,
    this.orientacaoRealizada,
    this.regraDeOuro = false,
    this.responsavelDesvioId,
    this.responsavelTratativaId,
    this.emailsManuais = const [],
    this.emailsPadraoExcluidos = const [],
  });

  Map<String, dynamic> toJson() => {
    'estabelecimentoId': estabelecimentoId,
    'titulo': titulo,
    if (localizacaoId != null) 'localizacaoId': localizacaoId,
    if (descricao != null) 'descricao': descricao,
    if (orientacaoRealizada != null) 'orientacaoRealizada': orientacaoRealizada,
    'regraDeOuro': regraDeOuro,
    if (responsavelDesvioId != null) 'responsavelDesvioId': responsavelDesvioId,
    if (responsavelTratativaId != null) 'responsavelTratativaId': responsavelTratativaId,
    'emailsManuais': emailsManuais,
    'emailsPadraoExcluidos': emailsPadraoExcluidos,
  };
}
