// lib/core/database/rascunhos_dao.dart
import 'package:drift/drift.dart';
import 'app_database.dart';

part 'rascunhos_dao.g.dart';

@DriftAccessor(tables: [Rascunhos])
class RascunhosDao extends DatabaseAccessor<AppDatabase>
    with _$RascunhosDaoMixin {
  RascunhosDao(super.db);

  Future<void> salvar(RascunhosCompanion companion) =>
      into(rascunhos).insertOnConflictUpdate(companion);

  Future<List<Rascunho>> listarPendentes() =>
      (select(rascunhos)..where((t) => t.sincronizado.equals(0))).get();

  Stream<List<Rascunho>> watchTodos() =>
      (select(rascunhos)
            ..orderBy([(t) => OrderingTerm.desc(t.criadoEm)]))
          .watch();

  Future<void> marcarSincronizado(String id, String serverId) =>
      (update(rascunhos)..where((t) => t.id.equals(id))).write(
        RascunhosCompanion(
          sincronizado: const Value(1),
          serverId: Value(serverId),
        ),
      );

  Future<void> deletar(String id) =>
      (delete(rascunhos)..where((t) => t.id.equals(id))).go();
}
