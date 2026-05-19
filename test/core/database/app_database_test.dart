// test/core/database/app_database_test.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  test('insert and list rascunho pendente', () async {
    await db.rascunhosDao.salvar(RascunhosCompanion.insert(
      id: '550e8400-e29b-41d4-a716-446655440000',
      tipo: 'NC',
      titulo: 'Teste NC',
      criadoEm: DateTime.now().millisecondsSinceEpoch,
      sincronizado: const Value(0),
    ));

    final pendentes = await db.rascunhosDao.listarPendentes();
    expect(pendentes.length, 1);
    expect(pendentes.first.titulo, 'Teste NC');
  });

  test('marcarSincronizado updates sincronizado to 1', () async {
    await db.rascunhosDao.salvar(RascunhosCompanion.insert(
      id: 'test-id',
      tipo: 'DESVIO',
      titulo: 'Desvio X',
      criadoEm: DateTime.now().millisecondsSinceEpoch,
      sincronizado: const Value(0),
    ));

    await db.rascunhosDao.marcarSincronizado('test-id', 'server-uuid-123');
    final pendentes = await db.rascunhosDao.listarPendentes();
    expect(pendentes, isEmpty);
  });
}
