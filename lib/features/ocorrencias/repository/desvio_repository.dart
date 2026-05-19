import '../model/desvio_summary.dart';
import '../model/criar_desvio_request.dart';

abstract class DesvioRepository {
  Future<List<DesvioSummary>> listar({String? estabelecimentoId});
  Future<Map<String, dynamic>> buscarPorId(String id);
  Future<Map<String, dynamic>> criar(CriarDesvioRequest request);
}
