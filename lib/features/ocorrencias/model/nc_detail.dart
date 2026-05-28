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
  final String? ncAnteriorId;
  final String? ncAnteriorTitulo;
  final String estabelecimentoId;
  final String estabelecimentoNome;
  final String usuarioCriacaoNome;
  final String? usuarioCriacaoEmail;
  final String? usuarioCriacaoId;
  final String? localizacaoNome;
  final String? dataLimiteResolucao;
  final String dataRegistro;
  final bool vencida;
  final String? responsavelTrativaNome;
  final String? responsavelTrativaEmail;
  final String? responsavelTrativaPerfil;
  final String? responsavelNcNome;
  final String? responsavelNcEmail;
  final String? responsavelNcPerfil;
  final List<Map<String, dynamic>> atividades;
  final List<Map<String, dynamic>> historico;
  final List<Map<String, dynamic>> normas;
  final String? causaRaiz;
  final String? descricaoExecucao;
  final List<Map<String, dynamic>> porques;
  final List<Map<String, dynamic>> investigacaoSnapshots;
  final List<Map<String, dynamic>> execucaoSnapshots;

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
    this.ncAnteriorId,
    this.ncAnteriorTitulo,
    required this.estabelecimentoId,
    required this.estabelecimentoNome,
    required this.usuarioCriacaoNome,
    this.usuarioCriacaoEmail,
    this.usuarioCriacaoId,
    this.localizacaoNome,
    this.dataLimiteResolucao,
    required this.dataRegistro,
    this.vencida = false,
    this.responsavelTrativaNome,
    this.responsavelTrativaEmail,
    this.responsavelTrativaPerfil,
    this.responsavelNcNome,
    this.responsavelNcEmail,
    this.responsavelNcPerfil,
    this.atividades = const [],
    this.historico = const [],
    this.normas = const [],
    this.causaRaiz,
    this.descricaoExecucao,
    this.porques = const [],
    this.investigacaoSnapshots = const [],
    this.execucaoSnapshots = const [],
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
        ncAnteriorId: json['ncAnteriorId'] as String?,
        ncAnteriorTitulo: json['ncAnteriorTitulo'] as String?,
        estabelecimentoId: json['estabelecimentoId'] as String? ?? '',
        estabelecimentoNome: json['estabelecimentoNome'] as String? ?? '',
        usuarioCriacaoNome: json['usuarioCriacaoNome'] as String? ?? '',
        usuarioCriacaoEmail: json['usuarioCriacaoEmail'] as String?,
        usuarioCriacaoId: json['usuarioCriacaoId'] as String?,
        localizacaoNome: json['localizacaoNome'] as String?,
        dataLimiteResolucao: json['dataLimiteResolucao'] as String?,
        dataRegistro: json['dataRegistro'] as String? ?? '',
        vencida: _calcVencida(json),
        responsavelTrativaNome: json['responsavelTrativaNome'] as String?,
        responsavelTrativaEmail: json['responsavelTrativaEmail'] as String?,
        responsavelTrativaPerfil: json['responsavelTrativaPerfil'] as String?,
        responsavelNcNome: json['responsavelNcNome'] as String?,
        responsavelNcEmail: json['responsavelNcEmail'] as String?,
        responsavelNcPerfil: json['responsavelNcPerfil'] as String?,
        atividades: (json['atividades'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>(),
        historico: (json['historico'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>(),
        normas: (json['normas'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>(),
        causaRaiz: json['causaRaiz'] as String?,
        descricaoExecucao: json['descricaoExecucao'] as String?,
        porques: _buildPorques(json),
        investigacaoSnapshots: (json['investigacaoSnapshots'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>(),
        execucaoSnapshots: (json['execucaoSnapshots'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>(),
      );
}

List<Map<String, dynamic>> _buildPorques(Map<String, dynamic> json) {
  const names = ['Um', 'Dois', 'Tres', 'Quatro', 'Cinco'];
  final result = <Map<String, dynamic>>[];
  for (final n in names) {
    final p = json['porque$n'] as String?;
    final r = json['porque${n}Resposta'] as String?;
    if (p != null && p.isNotEmpty) result.add({'pergunta': p, 'resposta': r ?? ''});
  }
  return result;
}

bool _calcVencida(Map<String, dynamic> json) {
  final status = json['status'] as String? ?? '';
  if (status == 'CONCLUIDA' || status == 'FECHADA' || status == 'APROVADA') return false;
  if (json['vencida'] == true) return true;
  final prazo = json['dataLimiteResolucao'] as String?;
  if (prazo == null) return false;
  try { return DateTime.parse(prazo).isBefore(DateTime.now()); } catch (_) { return false; }
}
