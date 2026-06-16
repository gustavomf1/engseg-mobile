const _imageExtensions = {'jpg', 'jpeg', 'png', 'gif', 'webp'};

class OcorrenciaSummary {
  final String tipo;
  final String id;
  final String titulo;
  final String status;
  final String estabelecimentoNome;
  final String dataRegistro;
  final String? responsavelTratativaId;
  // NC-specific
  final String? nivelRisco;
  final bool vencida;
  final String? dataLimiteResolucao;
  // Evidence
  final String? primeiraEvidenciaId;
  final String? primeiraEvidenciaNome;

  const OcorrenciaSummary({
    required this.tipo,
    required this.id,
    required this.titulo,
    required this.status,
    required this.estabelecimentoNome,
    required this.dataRegistro,
    this.responsavelTratativaId,
    this.nivelRisco,
    this.vencida = false,
    this.dataLimiteResolucao,
    this.primeiraEvidenciaId,
    this.primeiraEvidenciaNome,
  });

  factory OcorrenciaSummary.fromJson(Map<String, dynamic> json) {
    final tipo = json['tipo'] as String;
    final status = json['status'] as String;
    final concluida =
        status == 'CONCLUIDA' || status == 'FECHADA' || status == 'APROVADA';
    final prazoStr = json['dataLimiteResolucao'] as String?;
    bool vencida = json['vencida'] as bool? ?? false;
    if (!concluida && prazoStr != null) {
      try {
        vencida = DateTime.parse(prazoStr).isBefore(DateTime.now());
      } catch (_) {}
    }
    return OcorrenciaSummary(
      tipo: tipo,
      id: json['id'] as String,
      titulo: json['titulo'] as String? ?? '',
      status: status,
      estabelecimentoNome: json['estabelecimentoNome'] as String? ?? '',
      dataRegistro: json['dataRegistro'] as String? ?? '',
      responsavelTratativaId: json['responsavelTratativaId'] as String?,
      nivelRisco: json['nivelRisco'] as String?,
      vencida: vencida,
      dataLimiteResolucao: prazoStr,
      primeiraEvidenciaId: json['primeiraEvidenciaId'] as String?,
      primeiraEvidenciaNome: json['primeiraEvidenciaNome'] as String?,
    );
  }

  bool get isNc => tipo == 'NAO_CONFORMIDADE';
  bool get isDesvio => tipo == 'DESVIO';

  bool get hasImageCover {
    if (primeiraEvidenciaNome == null) return false;
    final ext = primeiraEvidenciaNome!.split('.').last.toLowerCase();
    return _imageExtensions.contains(ext);
  }

  bool get hasAnyCover => primeiraEvidenciaId != null;
}
