import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:engseg_mobile/features/ocorrencias/repository/nc_repository_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late NcRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    dio = MockDio();
    repo = NcRepositoryImpl(dio: dio, cacheDao: null);
  });

  test('listar returns list of NcSummary from API', () async {
    when(() => dio.get<List<dynamic>>(
      any(),
      queryParameters: any(named: 'queryParameters'),
    )).thenAnswer((_) async => Response(
      requestOptions: RequestOptions(path: ''),
      statusCode: 200,
      data: [
        {
          'id': 'nc-1',
          'titulo': 'NC de teste',
          'status': 'ABERTA',
          'nivelRisco': 'ALTO',
          'estabelecimentoNome': 'Refinaria XYZ',
          'dataRegistro': '2026-05-19T10:00:00Z',
          'vencida': false,
        }
      ],
    ));

    final result = await repo.listar(estabelecimentoId: 'est-1');
    expect(result.length, 1);
    expect(result.first.titulo, 'NC de teste');
  });

  test('listar parseia responsavelTratativaId a partir do campo responsavelTrativaId', () async {
    when(() => dio.get<List<dynamic>>(
      any(),
      queryParameters: any(named: 'queryParameters'),
    )).thenAnswer((_) async => Response(
      requestOptions: RequestOptions(path: ''),
      statusCode: 200,
      data: [
        {
          'id': 'nc-1',
          'titulo': 'NC de teste',
          'status': 'ABERTA',
          'nivelRisco': 'ALTO',
          'estabelecimentoNome': 'Refinaria XYZ',
          'dataRegistro': '2026-05-19T10:00:00Z',
          'vencida': false,
          'responsavelTrativaId': 'user-123',
        }
      ],
    ));

    final result = await repo.listar(estabelecimentoId: 'est-1');
    expect(result.first.responsavelTratativaId, 'user-123');
  });
}
