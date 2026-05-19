class NcSummary {
  final String id;
  final String titulo;
  final String status;
  final String nivelRisco;
  final String estabelecimentoNome;
  final String dataRegistro;
  final bool vencida;

  const NcSummary({
    required this.id,
    required this.titulo,
    required this.status,
    required this.nivelRisco,
    required this.estabelecimentoNome,
    required this.dataRegistro,
    required this.vencida,
  });

  factory NcSummary.fromJson(Map<String, dynamic> json) => NcSummary(
        id: json['id'] as String,
        titulo: json['titulo'] as String,
        status: json['status'] as String,
        nivelRisco: json['nivelRisco'] as String? ?? 'MEDIO',
        estabelecimentoNome: json['estabelecimentoNome'] as String? ?? '',
        dataRegistro: json['dataRegistro'] as String? ?? '',
        vencida: json['vencida'] as bool? ?? false,
      );
}
