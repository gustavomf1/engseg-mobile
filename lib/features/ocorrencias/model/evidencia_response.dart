class EvidenciaResponse {
  final String id;
  final String? url;
  final String tipo;

  const EvidenciaResponse({
    required this.id,
    this.url,
    required this.tipo,
  });

  factory EvidenciaResponse.fromJson(Map<String, dynamic> json) => EvidenciaResponse(
        id: json['id'].toString(),
        url: json['urlArquivo'] as String?,
        tipo: json['tipoEvidencia'] as String? ?? 'FOTO',
      );
}
