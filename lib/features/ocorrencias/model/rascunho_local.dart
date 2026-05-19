import 'dart:convert';

class RascunhoLocal {
  final String id;
  final String tipo; // "NC" | "DESVIO"
  final String titulo;
  final String? descricao;
  final int? severidade;
  final String? fotoPath;
  final double? latitude;
  final double? longitude;
  final int? capturedAt;
  final Map<String, dynamic> dadosJson;
  final int criadoEm;
  final int sincronizado;

  const RascunhoLocal({
    required this.id,
    required this.tipo,
    required this.titulo,
    this.descricao,
    this.severidade,
    this.fotoPath,
    this.latitude,
    this.longitude,
    this.capturedAt,
    required this.dadosJson,
    required this.criadoEm,
    this.sincronizado = 0,
  });

  String get dadosJsonEncoded => jsonEncode(dadosJson);
}
