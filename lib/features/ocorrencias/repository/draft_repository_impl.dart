import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/rascunho_local.dart';
import 'draft_repository.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/rascunhos_dao.dart';

final draftRepositoryProvider = Provider<DraftRepository>((ref) {
  return DraftRepositoryImpl(dao: ref.watch(appDatabaseProvider).rascunhosDao);
});

final draftsProvider = StreamProvider<List<RascunhoLocal>>((ref) {
  return ref.watch(draftRepositoryProvider).watchPendentes();
});

class DraftRepositoryImpl implements DraftRepository {
  final RascunhosDao dao;

  DraftRepositoryImpl({required this.dao});

  @override
  Stream<List<RascunhoLocal>> watchPendentes() {
    return dao.watchPendentes().map(
      (list) => list.map(_toModel).toList(),
    );
  }

  @override
  Future<void> salvar(RascunhoLocal rascunho) async {
    await dao.salvar(RascunhosCompanion.insert(
      id: rascunho.id,
      tipo: rascunho.tipo,
      titulo: rascunho.titulo,
      descricao: Value(rascunho.descricao),
      severidade: Value(rascunho.severidade),
      fotoPath: Value(rascunho.fotoPath),
      latitude: Value(rascunho.latitude),
      longitude: Value(rascunho.longitude),
      capturedAt: Value(rascunho.capturedAt),
      dadosJson: Value(rascunho.dadosJsonEncoded),
      criadoEm: rascunho.criadoEm,
      sincronizado: Value(rascunho.sincronizado),
    ));
  }

  @override
  Future<void> marcarSincronizado(String id, String serverId) =>
      dao.marcarSincronizado(id, serverId);

  @override
  Future<void> deletar(String id) => dao.deletar(id);

  RascunhoLocal _toModel(Rascunho row) => RascunhoLocal(
        id: row.id,
        tipo: row.tipo,
        titulo: row.titulo,
        descricao: row.descricao,
        severidade: row.severidade,
        fotoPath: row.fotoPath,
        latitude: row.latitude,
        longitude: row.longitude,
        capturedAt: row.capturedAt,
        dadosJson: const {},
        criadoEm: row.criadoEm,
        sincronizado: row.sincronizado,
      );
}
