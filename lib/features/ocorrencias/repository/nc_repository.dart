import '../model/nc_summary.dart';
import '../model/nc_detail.dart';
import '../model/criar_nc_request.dart';
import '../model/rascunho_local.dart';

abstract class NcRepository {
  Future<List<NcSummary>> listar({String? estabelecimentoId, String? status});
  Future<NcDetail> buscarPorId(String id);
  Future<NcDetail> criar(CriarNcRequest request);
  Future<void> salvarRascunho(RascunhoLocal rascunho);
}
