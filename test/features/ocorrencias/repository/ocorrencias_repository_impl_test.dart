import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:engseg_mobile/features/ocorrencias/model/ocorrencia_summary.dart';
import 'package:engseg_mobile/features/ocorrencias/repository/ocorrencias_repository_impl.dart';
import 'package:engseg_mobile/core/network/dio_client.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ProviderContainer container;

  setUp(() {
    mockDio = MockDio();
    container = ProviderContainer(
      overrides: [dioProvider.overrideWithValue(mockDio)],
    );
  });

  tearDown(() => container.dispose());

  final fakeResponse = [
    {
      'tipo': 'NAO_CONFORMIDADE',
      'id': 'nc-1',
      'titulo': 'NC A',
      'status': 'ABERTA',
      'estabelecimentoNome': 'Obra',
      'dataRegistro': '2026-01-01',
      'vencida': false,
      'primeiraEvidenciaId': 'ev-1',
      'primeiraEvidenciaNome': 'foto.png',
    },
    {
      'tipo': 'DESVIO',
      'id': 'dv-1',
      'titulo': 'Desvio A',
      'status': 'EM_ANALISE',
      'estabelecimentoNome': 'Canteiro',
      'dataRegistro': '2026-01-02',
    },
  ];

  test('parseia lista e separa por tipo', () async {
    when(() => mockDio.get<List<dynamic>>(
          '/api/ocorrencias',
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/api/ocorrencias'),
        data: fakeResponse,
        statusCode: 200,
      ),
    );

    final result = await container
        .read(ocorrenciasProvider(('ws-1', null)).future);

    expect(result.length, 2);
    expect(result.where((o) => o.isNc).length, 1);
    expect(result.where((o) => o.isDesvio).length, 1);
    expect(result.first.primeiraEvidenciaId, 'ev-1');
  });

  test('passa meuPapel no query quando fornecido', () async {
    when(() => mockDio.get<List<dynamic>>(
          '/api/ocorrencias',
          queryParameters: {'meuPapel': 'RESPONSAVEL_TRATATIVA_NC'},
        )).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/api/ocorrencias'),
        data: <dynamic>[],
        statusCode: 200,
      ),
    );

    final result = await container
        .read(ocorrenciasProvider((null, 'RESPONSAVEL_TRATATIVA_NC')).future);

    expect(result, isEmpty);
    verify(() => mockDio.get<List<dynamic>>(
          '/api/ocorrencias',
          queryParameters: {'meuPapel': 'RESPONSAVEL_TRATATIVA_NC'},
        )).called(1);
  });
}
