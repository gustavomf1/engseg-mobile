class EvidenciaMetadata {
  final double latitude;
  final double longitude;
  final int capturedAt; // epoch ms
  final String? cidade;

  const EvidenciaMetadata({
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.cidade,
  });
}
