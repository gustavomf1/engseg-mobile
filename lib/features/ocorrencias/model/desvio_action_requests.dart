class AdicionarTrativaRequest {
  final String titulo;
  final String descricao;
  final List<String> evidenciaIds;

  const AdicionarTrativaRequest({
    required this.titulo,
    required this.descricao,
    required this.evidenciaIds,
  });

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'descricao': descricao,
        'evidenciaIds': evidenciaIds,
      };
}

class SubmeterTrativaDesvioRequest {
  final List<String> emailsManuais;
  const SubmeterTrativaDesvioRequest({this.emailsManuais = const []});
  Map<String, dynamic> toJson() => {'emailsManuais': emailsManuais};
}

class AprovarDesvioRequest {
  final String? comentario;
  final List<String> emailsManuais;
  const AprovarDesvioRequest({this.comentario, this.emailsManuais = const []});
  Map<String, dynamic> toJson() => {
        if (comentario != null && comentario!.isNotEmpty) 'comentario': comentario,
        'emailsManuais': emailsManuais,
      };
}

class ItemReprovacao {
  final String trativaId;
  final String motivo;
  const ItemReprovacao({required this.trativaId, required this.motivo});
  Map<String, dynamic> toJson() => {'trativaId': trativaId, 'motivo': motivo};
}

class ReprovarTrativasDesvioRequest {
  final List<ItemReprovacao> itens;
  final List<String> emailsManuais;
  const ReprovarTrativasDesvioRequest({
    required this.itens,
    this.emailsManuais = const [],
  });
  Map<String, dynamic> toJson() => {
        'itens': itens.map((e) => e.toJson()).toList(),
        'emailsManuais': emailsManuais,
      };
}
