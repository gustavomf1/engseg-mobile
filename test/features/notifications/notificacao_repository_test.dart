import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:engseg_mobile/features/notifications/repository/notificacao_repository_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late NotificacaoRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    dio = MockDio();
    repo = NotificacaoRepositoryImpl(bffDio: dio);
  });

  test('listar retorna lista de NotificacaoItem a partir do content paginado', () async {
    when(() => dio.get<Map<String, dynamic>>(
      any(),
      queryParameters: any(named: 'queryParameters'),
    )).thenAnswer((_) async => Response(
      requestOptions: RequestOptions(path: ''),
      statusCode: 200,
      data: {
        'content': [
          {
            'id': 'notif-1',
            'ncId': 'nc-1',
            'tipo': 'NC_ATIVADA',
            'titulo': 'EngSeg — NC Teste',
            'corpo': 'corpo do push',
            'lida': false,
            'criadoEm': '2026-06-19T10:00:00',
          }
        ],
        'totalElements': 1,
      },
    ));

    final result = await repo.listar();
    expect(result.length, 1);
    expect(result.first.titulo, 'EngSeg — NC Teste');
    expect(result.first.lida, false);
  });

  test('marcarComoLida chama POST /notificacoes/{id}/lida', () async {
    when(() => dio.post<void>(any())).thenAnswer((_) async => Response(
      requestOptions: RequestOptions(path: ''),
      statusCode: 200,
    ));

    await repo.marcarComoLida('notif-1');

    verify(() => dio.post<void>('/notificacoes/notif-1/lida')).called(1);
  });
}
