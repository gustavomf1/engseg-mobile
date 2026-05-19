// lib/core/database/ocorrencias_cache_dao.dart
import 'package:drift/drift.dart';
import 'app_database.dart';

part 'ocorrencias_cache_dao.g.dart';

@DriftAccessor(tables: [OcorrenciasCache])
class OcorrenciasCacheDao extends DatabaseAccessor<AppDatabase>
    with _$OcorrenciasCacheDaoMixin {
  OcorrenciasCacheDao(super.db);

  Future<void> salvar(OcorrenciasCacheCompanion companion) =>
      into(ocorrenciasCache).insertOnConflictUpdate(companion);

  Future<List<OcorrenciasCacheData>> listarPorTipo(String tipo) =>
      (select(ocorrenciasCache)..where((t) => t.tipo.equals(tipo))).get();

  Future<void> limpar(String tipo) =>
      (delete(ocorrenciasCache)..where((t) => t.tipo.equals(tipo))).go();
}
