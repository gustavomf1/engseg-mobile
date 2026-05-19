import '../model/usuario_summary.dart';
import '../model/localizacao.dart';
import '../model/norma.dart';
import '../model/estabelecimento.dart';

abstract class SupportRepository {
  Future<List<UsuarioSummary>> listarUsuarios(String estabelecimentoId);
  Future<List<Localizacao>> listarLocalizacoes(String estabelecimentoId);
  Future<List<Norma>> listarNormas();
  Future<List<Estabelecimento>> listarEstabelecimentos();
}
