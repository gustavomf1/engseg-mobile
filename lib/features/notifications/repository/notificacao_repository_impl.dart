import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/notificacao_item.dart';
import 'notificacao_repository.dart';
import '../../../core/network/dio_client.dart';

final notificacaoRepositoryProvider = Provider<NotificacaoRepository>((ref) {
  return NotificacaoRepositoryImpl(bffDio: ref.watch(bffDioProvider));
});

final notificacoesProvider = FutureProvider<List<NotificacaoItem>>((ref) async {
  return ref.watch(notificacaoRepositoryProvider).listar();
});

class NotificacaoRepositoryImpl implements NotificacaoRepository {
  final Dio bffDio;

  NotificacaoRepositoryImpl({required this.bffDio});

  @override
  Future<List<NotificacaoItem>> listar({int page = 0, int size = 20}) async {
    final response = await bffDio.get<Map<String, dynamic>>(
      '/notificacoes',
      queryParameters: {'page': page, 'size': size},
    );
    final content = (response.data?['content'] as List<dynamic>?) ?? [];
    return content
        .map((e) => NotificacaoItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> marcarComoLida(String id) async {
    await bffDio.post<void>('/notificacoes/$id/lida');
  }
}
