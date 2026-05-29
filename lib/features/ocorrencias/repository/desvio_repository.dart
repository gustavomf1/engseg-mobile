import '../model/desvio_summary.dart';
import '../model/desvio_detail.dart';
import '../model/criar_desvio_request.dart';
import '../model/desvio_action_requests.dart';

abstract class DesvioRepository {
  Future<List<DesvioSummary>> listar({String? estabelecimentoId});
  Future<DesvioDetail> buscarDetalhe(String id);
  Future<Map<String, dynamic>> criar(CriarDesvioRequest request);
  Future<void> abrirTratativa(String id);
  Future<void> adicionarTratativa(String id, AdicionarTrativaRequest request);
  Future<void> removerTratativa(String id, String trativaId);
  Future<void> submeterTratativa(String id, SubmeterTrativaDesvioRequest request);
  Future<void> aprovar(String id, AprovarDesvioRequest request);
  Future<void> reprovar(String id, ReprovarTrativasDesvioRequest request);
}
