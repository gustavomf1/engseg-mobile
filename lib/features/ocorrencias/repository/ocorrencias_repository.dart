import '../model/ocorrencia_summary.dart';

abstract interface class OcorrenciasRepository {
  Future<List<OcorrenciaSummary>> listar({
    String? estabelecimentoId,
    String? meuPapel,
  });
}
