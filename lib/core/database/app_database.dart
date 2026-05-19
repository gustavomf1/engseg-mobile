// lib/core/database/app_database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'rascunhos_dao.dart';
import 'ocorrencias_cache_dao.dart';

part 'app_database.g.dart';

class Rascunhos extends Table {
  TextColumn get id => text()();
  TextColumn get tipo => text()();
  TextColumn get titulo => text()();
  TextColumn get descricao => text().nullable()();
  IntColumn get severidade => integer().nullable()();
  TextColumn get fotoPath => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  IntColumn get capturedAt => integer().nullable()();
  TextColumn get dadosJson => text().nullable()();
  IntColumn get criadoEm => integer()();
  IntColumn get sincronizado => integer().withDefault(const Constant(0))();
  TextColumn get serverId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class OcorrenciasCache extends Table {
  TextColumn get id => text()();
  TextColumn get tipo => text()();
  TextColumn get dadosJson => text()();
  TextColumn get usuarioId => text()();
  IntColumn get cachedEm => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [Rascunhos, OcorrenciasCache],
  daos: [RascunhosDao, OcorrenciasCacheDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase(_openConnection());
});

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'engseg.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
