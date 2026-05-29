import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:engseg_mobile/features/ocorrencias/model/desvio_action_requests.dart';
import 'package:engseg_mobile/features/ocorrencias/repository/desvio_repository_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late DesvioRepositoryImpl repo;

  setUpAll(() => registerFallbackValue(RequestOptions(path: '')));
  setUp(() {
    dio = MockDio();
    repo = DesvioRepositoryImpl(dio: dio);
  });

  test('buscarDetalhe parseia DesvioDetail', () async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: {'id': 'd-1', 'titulo': 'X', 'status': 'ABERTO', 'tratativas': []},
        ));
    final d = await repo.buscarDetalhe('d-1');
    expect(d.id, 'd-1');
    expect(d.status, 'ABERTO');
  });

  test('adicionarTratativa faz POST no endpoint correto', () async {
    when(() => dio.post<dynamic>(any(), data: any(named: 'data')))
        .thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''), statusCode: 200));
    await repo.adicionarTratativa(
      'd-1',
      const AdicionarTrativaRequest(titulo: 'T', descricao: 'D', evidenciaIds: ['e1']),
    );
    verify(() => dio.post<dynamic>('/api/desvios/d-1/tratativas',
        data: any(named: 'data'))).called(1);
  });

  test('abrirTratativa faz POST no endpoint correto', () async {
    when(() => dio.post<dynamic>(any())).thenAnswer((_) async =>
        Response(requestOptions: RequestOptions(path: ''), statusCode: 200));
    await repo.abrirTratativa('d-1');
    verify(() => dio.post<dynamic>('/api/desvios/d-1/abrir-tratativa')).called(1);
  });
}
