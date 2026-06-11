import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/desvio_summary.dart';
import '../model/desvio_detail.dart';
import '../model/criar_desvio_request.dart';
import '../model/desvio_action_requests.dart';
import 'desvio_repository.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';

final desvioRepositoryProvider = Provider<DesvioRepository>((ref) {
  return DesvioRepositoryImpl(dio: ref.watch(dioProvider));
});

final desvioListProvider = FutureProvider.family<List<DesvioSummary>, String?>(
  (ref, estabelecimentoId) async {
    return ref.read(desvioRepositoryProvider).listar(
          estabelecimentoId: estabelecimentoId,
        );
  },
);

final desvioDetailProvider = FutureProvider.family<DesvioDetail, String>(
  (ref, id) async {
    return ref.watch(desvioRepositoryProvider).buscarDetalhe(id);
  },
);

/// Fotos de ocorrência do Desvio (não vêm no DesvioResponse)
final desvioEvidenciasProvider = FutureProvider.family<List<String>, String>(
  (ref, id) async {
    final dio = ref.watch(dioProvider);
    try {
      final r = await dio.get<List<dynamic>>(
        '/api/evidencias/desvio/$id',
        queryParameters: {'tipo': 'OCORRENCIA'},
      );
      return (r.data ?? [])
          .map((e) {
            final id = (e as Map<String, dynamic>)['id'];
            if (id == null) return '';
            return '${AppConfig.apiBaseUrl}/api/evidencias/$id/download';
          })
          .where((url) => url.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  },
);

class DesvioRepositoryImpl implements DesvioRepository {
  final Dio dio;
  DesvioRepositoryImpl({required this.dio});

  @override
  Future<List<DesvioSummary>> listar({String? estabelecimentoId}) async {
    final response = await dio.get<List<dynamic>>(
      '/api/desvios',
      queryParameters: {
        if (estabelecimentoId != null) 'estabelecimentoId': estabelecimentoId,
      },
    );
    return (response.data ?? [])
        .map((e) => DesvioSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DesvioDetail> buscarDetalhe(String id) async {
    final response = await dio.get<Map<String, dynamic>>('/api/desvios/$id');
    return DesvioDetail.fromJson(response.data!);
  }

  @override
  Future<Map<String, dynamic>> criar(CriarDesvioRequest request) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/api/desvios',
      data: request.toJson(),
    );
    return response.data!;
  }

  @override
  Future<void> abrirTratativa(String id) async {
    await dio.post<dynamic>('/api/desvios/$id/abrir-tratativa');
  }

  @override
  Future<void> adicionarTratativa(String id, AdicionarTrativaRequest request) async {
    await dio.post<dynamic>('/api/desvios/$id/tratativas', data: request.toJson());
  }

  @override
  Future<void> removerTratativa(String id, String trativaId) async {
    await dio.delete<dynamic>('/api/desvios/$id/tratativas/$trativaId');
  }

  @override
  Future<void> submeterTratativa(String id, SubmeterTrativaDesvioRequest request) async {
    await dio.post<dynamic>('/api/desvios/$id/submeter-tratativa', data: request.toJson());
  }

  @override
  Future<void> aprovar(String id, AprovarDesvioRequest request) async {
    await dio.post<dynamic>('/api/desvios/$id/aprovar', data: request.toJson());
  }

  @override
  Future<void> reprovar(String id, ReprovarTrativasDesvioRequest request) async {
    await dio.post<dynamic>('/api/desvios/$id/reprovar', data: request.toJson());
  }
}
