class EvidenciaResponse {
  final String id;
  final String url;
  final String tipo;

  const EvidenciaResponse({
    required this.id,
    required this.url,
    required this.tipo,
  });

  factory EvidenciaResponse.fromJson(Map<String, dynamic> json) => EvidenciaResponse(
        id: json['id'] as String,
        url: json['url'] as String,
        tipo: json['tipo'] as String? ?? 'FOTO',
      );
}
