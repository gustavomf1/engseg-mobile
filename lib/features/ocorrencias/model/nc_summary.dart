class NcSummary {
  final String id;
  final String titulo;
  final String status;
  final String nivelRisco;
  final String estabelecimentoNome;
  final String dataRegistro;
  final bool vencida;
  final String? responsavelTratativaId;

  const NcSummary({
    required this.id,
    required this.titulo,
    required this.status,
    required this.nivelRisco,
    required this.estabelecimentoNome,
    required this.dataRegistro,
    required this.vencida,
    this.responsavelTratativaId,
  });

  factory NcSummary.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String;
    final concluida = status == 'CONCLUIDA' || status == 'FECHADA' || status == 'APROVADA';
    final prazoStr = json['dataLimiteResolucao'] as String?;
    final vencidaApi = json['vencida'] as bool? ?? false;
    bool vencida = vencidaApi;
    if (!concluida && prazoStr != null) {
      try {
        vencida = DateTime.parse(prazoStr).isBefore(DateTime.now());
      } catch (_) {}
    }
    return NcSummary(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      status: status,
      nivelRisco: json['nivelRisco'] as String? ?? 'MEDIO',
      estabelecimentoNome: json['estabelecimentoNome'] as String? ?? '',
      dataRegistro: json['dataRegistro'] as String? ?? '',
      vencida: vencida,
      responsavelTratativaId: json['responsavelTrativaId'] as String?,
    );
  }
}
