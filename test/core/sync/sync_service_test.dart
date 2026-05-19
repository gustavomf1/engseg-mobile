import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:engseg_mobile/core/sync/sync_service.dart';
import 'package:engseg_mobile/features/ocorrencias/model/rascunho_local.dart';
import 'package:engseg_mobile/features/ocorrencias/repository/draft_repository.dart';

class MockDio extends Mock implements Dio {}
class MockDraftRepository extends Mock implements DraftRepository {}

void main() {
  late MockDio dio;
  late MockDraftRepository drafts;
  late SyncService service;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(RascunhoLocal(
      id: '', tipo: 'NC', titulo: '', dadosJson: {}, criadoEm: 0,
    ));
  });

  setUp(() {
    dio = MockDio();
    drafts = MockDraftRepository();
    service = SyncService(bffDio: dio, draftRepository: drafts);
  });

  test('sync marks drafts as synchronized on CRIADO response', () async {
    final rascunho = RascunhoLocal(
      id: 'local-1',
      tipo: 'NC',
      titulo: 'Teste',
      dadosJson: {'estabelecimentoId': 'est-1', 'titulo': 'Teste'},
      criadoEm: DateTime.now().millisecondsSinceEpoch,
    );

    when(() => drafts.watchPendentes()).thenAnswer(
      (_) => Stream.value([rascunho]),
    );
    when(() => dio.post<Map<String, dynamic>>(
      any(),
      data: any(named: 'data'),
      options: any(named: 'options'),
    )).thenAnswer((_) async => Response(
      requestOptions: RequestOptions(path: ''),
      statusCode: 200,
      data: {
        'results': [
          {'localId': 'local-1', 'serverId': 'server-uuid', 'status': 'CRIADO', 'erro': null}
        ]
      },
    ));
    when(() => drafts.marcarSincronizado('local-1', 'server-uuid'))
        .thenAnswer((_) async {});

    await service.syncPendentes(token: 'jwt-token');
    verify(() => drafts.marcarSincronizado('local-1', 'server-uuid')).called(1);
  });
}
