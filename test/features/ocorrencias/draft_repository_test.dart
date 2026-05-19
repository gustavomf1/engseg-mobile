import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/core/database/app_database.dart';
import 'package:engseg_mobile/features/ocorrencias/model/rascunho_local.dart';
import 'package:engseg_mobile/features/ocorrencias/repository/draft_repository_impl.dart';

void main() {
  late AppDatabase db;
  late DraftRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DraftRepositoryImpl(dao: db.rascunhosDao);
  });

  tearDown(() async => db.close());

  test('salvar and watchPendentes emits saved draft', () async {
    await repo.salvar(RascunhoLocal(
      id: 'draft-1',
      tipo: 'NC',
      titulo: 'Rascunho NC',
      dadosJson: {'estabelecimentoId': 'est-1'},
      criadoEm: DateTime.now().millisecondsSinceEpoch,
    ));

    final stream = repo.watchPendentes();
    final list = await stream.first;
    expect(list.length, 1);
    expect(list.first.titulo, 'Rascunho NC');
  });

  test('deletar removes draft', () async {
    await repo.salvar(RascunhoLocal(
      id: 'draft-2',
      tipo: 'DESVIO',
      titulo: 'Desvio X',
      dadosJson: {},
      criadoEm: DateTime.now().millisecondsSinceEpoch,
    ));
    await repo.deletar('draft-2');

    final list = await repo.watchPendentes().first;
    expect(list, isEmpty);
  });
}
