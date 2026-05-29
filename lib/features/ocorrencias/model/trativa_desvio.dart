import '../../../core/config/app_config.dart';

class EvidenciaInfo {
  final String id;
  final String nome;
  final String? url;
  const EvidenciaInfo({required this.id, required this.nome, this.url});

  factory EvidenciaInfo.fromJson(Map<String, dynamic> j) {
    final raw = j['urlArquivo'] as String?;
    final url = raw != null && raw.startsWith('/')
        ? '${AppConfig.apiBaseUrl}$raw'
        : raw;
    return EvidenciaInfo(
      id: j['id'] as String,
      nome: j['nome'] as String? ?? '',
      url: url,
    );
  }
}

class TrativaDesvio {
  final String id;
  final String titulo;
  final String descricao;
  final String status; // PENDENTE | APROVADO | REPROVADO
  final String? motivoReprovacao;
  final int numero;
  final int rodada;
  final String? dtCriacao;
  final List<EvidenciaInfo> evidencias;

  const TrativaDesvio({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.status,
    this.motivoReprovacao,
    required this.numero,
    required this.rodada,
    this.dtCriacao,
    this.evidencias = const [],
  });

  factory TrativaDesvio.fromJson(Map<String, dynamic> j) => TrativaDesvio(
        id: j['id'] as String,
        titulo: j['titulo'] as String? ?? '',
        descricao: j['descricao'] as String? ?? '',
        status: j['status'] as String? ?? 'PENDENTE',
        motivoReprovacao: j['motivoReprovacao'] as String?,
        numero: j['numero'] as int? ?? 0,
        rodada: j['rodada'] as int? ?? 1,
        dtCriacao: j['dtCriacao'] as String?,
        evidencias: (j['evidencias'] as List<dynamic>? ?? [])
            .map((e) => EvidenciaInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
