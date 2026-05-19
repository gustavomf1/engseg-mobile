class NcDetail {
  final String id;
  final String titulo;
  final String? descricao;
  final String status;
  final String nivelRisco;
  final int severidade;
  final int probabilidade;
  final bool regraDeOuro;
  final bool reincidencia;
  final String estabelecimentoId;
  final String estabelecimentoNome;
  final String usuarioCriacaoNome;
  final String? localizacaoNome;
  final String? dataLimiteResolucao;
  final String dataRegistro;

  const NcDetail({
    required this.id,
    required this.titulo,
    this.descricao,
    required this.status,
    required this.nivelRisco,
    required this.severidade,
    required this.probabilidade,
    required this.regraDeOuro,
    required this.reincidencia,
    required this.estabelecimentoId,
    required this.estabelecimentoNome,
    required this.usuarioCriacaoNome,
    this.localizacaoNome,
    this.dataLimiteResolucao,
    required this.dataRegistro,
  });

  factory NcDetail.fromJson(Map<String, dynamic> json) => NcDetail(
        id: json['id'] as String,
        titulo: json['titulo'] as String,
        descricao: json['descricao'] as String?,
        status: json['status'] as String,
        nivelRisco: json['nivelRisco'] as String? ?? 'MEDIO',
        severidade: json['severidade'] as int? ?? 1,
        probabilidade: json['probabilidade'] as int? ?? 1,
        regraDeOuro: json['regraDeOuro'] as bool? ?? false,
        reincidencia: json['reincidencia'] as bool? ?? false,
        estabelecimentoId: json['estabelecimentoId'] as String? ?? '',
        estabelecimentoNome: json['estabelecimentoNome'] as String? ?? '',
        usuarioCriacaoNome: json['usuarioCriacaoNome'] as String? ?? '',
        localizacaoNome: json['localizacaoNome'] as String?,
        dataLimiteResolucao: json['dataLimiteResolucao'] as String?,
        dataRegistro: json['dataRegistro'] as String? ?? '',
      );
}
