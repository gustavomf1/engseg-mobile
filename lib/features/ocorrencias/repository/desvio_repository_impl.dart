import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/desvio_summary.dart';
import '../model/criar_desvio_request.dart';
import 'desvio_repository.dart';
import '../../../core/network/dio_client.dart';

final desvioListProvider = FutureProvider.family<List<DesvioSummary>, String>(
  (ref, estabelecimentoId) async {
    return ref.read(desvioRepositoryProvider).listar(
          estabelecimentoId: estabelecimentoId,
        );
  },
);

final desvioRepositoryProvider = Provider<DesvioRepository>((ref) {
  return DesvioRepositoryImpl(dio: ref.watch(dioProvider));
});

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
  Future<Map<String, dynamic>> buscarPorId(String id) async {
    final response = await dio.get<Map<String, dynamic>>('/api/desvios/$id');
    return response.data!;
  }

  @override
  Future<Map<String, dynamic>> criar(CriarDesvioRequest request) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/api/desvios',
      data: request.toJson(),
    );
    return response.data!;
  }
}
