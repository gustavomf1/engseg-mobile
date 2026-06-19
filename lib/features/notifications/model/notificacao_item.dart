class NotificacaoItem {
  final String id;
  final String ncId;
  final String tipo;
  final String titulo;
  final String corpo;
  final bool lida;
  final DateTime criadoEm;

  const NotificacaoItem({
    required this.id,
    required this.ncId,
    required this.tipo,
    required this.titulo,
    required this.corpo,
    required this.lida,
    required this.criadoEm,
  });

  factory NotificacaoItem.fromJson(Map<String, dynamic> json) {
    return NotificacaoItem(
      id: json['id'] as String,
      ncId: json['ncId'] as String,
      tipo: json['tipo'] as String,
      titulo: json['titulo'] as String,
      corpo: json['corpo'] as String,
      lida: json['lida'] as bool? ?? false,
      criadoEm: DateTime.parse(json['criadoEm'] as String),
    );
  }
}
