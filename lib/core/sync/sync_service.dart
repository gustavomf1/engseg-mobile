import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../../features/ocorrencias/repository/draft_repository.dart';
import '../../features/ocorrencias/repository/draft_repository_impl.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  // bffDio com Bearer + refresh-on-401 (token lido do storage a cada requisição).
  final bffDio = ref.watch(bffDioProvider);
  return SyncService(
    bffDio: bffDio,
    draftRepository: ref.watch(draftRepositoryProvider),
  );
});

class SyncService {
  final Dio bffDio;
  final DraftRepository draftRepository;

  SyncService({required this.bffDio, required this.draftRepository});

  Future<void> syncPendentes() async {
    final pendentes = await draftRepository.watchPendentes().first;
    if (pendentes.isEmpty) return;

    final items = pendentes.map((r) {
      final data = <String, dynamic>{'localId': r.id, 'tipo': r.tipo};
      if (r.tipo == 'NC') {
        data['nc'] = r.dadosJson;
      } else {
        data['desvio'] = r.dadosJson;
      }
      return data;
    }).toList();

    final response = await bffDio.post<Map<String, dynamic>>(
      '/sync/batch',
      data: {'items': items},
    );

    final results = (response.data?['results'] as List<dynamic>?) ?? [];
    for (final result in results) {
      final r = result as Map<String, dynamic>;
      if (r['status'] == 'CRIADO' && r['serverId'] != null) {
        await draftRepository.marcarSincronizado(
          r['localId'] as String,
          r['serverId'] as String,
        );
      }
    }
  }
}
