class DesvioSummary {
  final String id;
  final String titulo;
  final String status;
  final String estabelecimentoNome;
  final String dataRegistro;
  final String? responsavelTratativaId;

  const DesvioSummary({
    required this.id,
    required this.titulo,
    required this.status,
    required this.estabelecimentoNome,
    required this.dataRegistro,
    this.responsavelTratativaId,
  });

  factory DesvioSummary.fromJson(Map<String, dynamic> json) => DesvioSummary(
    id: json['id'] as String,
    titulo: json['titulo'] as String,
    status: json['status'] as String,
    estabelecimentoNome: json['estabelecimentoNome'] as String? ?? '',
    dataRegistro: json['dataRegistro'] as String? ?? '',
    responsavelTratativaId: json['responsavelTratativaId'] as String?,
  );
}
