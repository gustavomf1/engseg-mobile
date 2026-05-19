import '../model/rascunho_local.dart';

abstract class DraftRepository {
  Stream<List<RascunhoLocal>> watchPendentes();
  Future<void> salvar(RascunhoLocal rascunho);
  Future<void> marcarSincronizado(String id, String serverId);
  Future<void> deletar(String id);
}
