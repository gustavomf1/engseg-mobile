import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/nc_summary.dart';
import '../model/nc_detail.dart';
import '../model/criar_nc_request.dart';
import '../model/rascunho_local.dart';
import 'nc_repository.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/ocorrencias_cache_dao.dart';

final ncListProvider = FutureProvider.family<List<NcSummary>, String>(
  (ref, estabelecimentoId) async {
    return ref.read(ncRepositoryProvider).listar(
          estabelecimentoId: estabelecimentoId,
        );
  },
);

final ncRepositoryProvider = Provider<NcRepository>((ref) {
  return NcRepositoryImpl(
    dio: ref.watch(dioProvider),
    cacheDao: ref.watch(appDatabaseProvider).ocorrenciasCacheDao,
  );
});

class NcRepositoryImpl implements NcRepository {
  final Dio dio;
  final OcorrenciasCacheDao? cacheDao;

  NcRepositoryImpl({required this.dio, required this.cacheDao});

  @override
  Future<List<NcSummary>> listar({
    String? estabelecimentoId,
    String? status,
  }) async {
    try {
      final response = await dio.get<List<dynamic>>(
        '/api/nao-conformidades',
        queryParameters: {
          if (estabelecimentoId != null) 'estabelecimentoId': estabelecimentoId,
          if (status != null) 'status': status,
        },
      );
      final list = (response.data ?? [])
          .map((e) => NcSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      await cacheDao?.limpar('NC');
      for (final nc in list) {
        await cacheDao?.salvar(OcorrenciasCacheCompanion.insert(
          id: nc.id,
          tipo: 'NC',
          dadosJson: jsonEncode({'titulo': nc.titulo, 'status': nc.status}),
          usuarioId: '',
          cachedEm: DateTime.now().millisecondsSinceEpoch,
        ));
      }
      return list;
    } on DioException catch (_) {
      final cached = await cacheDao?.listarPorTipo('NC') ?? [];
      return cached.map((c) {
        final data = jsonDecode(c.dadosJson) as Map<String, dynamic>;
        return NcSummary(
          id: c.id,
          titulo: data['titulo'] as String,
          status: data['status'] as String,
          nivelRisco: 'MEDIO',
          estabelecimentoNome: '',
          dataRegistro: '',
          vencida: false,
        );
      }).toList();
    }
  }

  @override
  Future<NcDetail> buscarPorId(String id) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/api/nao-conformidades/$id',
    );
    return NcDetail.fromJson(response.data!);
  }

  @override
  Future<NcDetail> criar(CriarNcRequest request) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/api/nao-conformidades',
      data: request.toJson(),
    );
    return NcDetail.fromJson(response.data!);
  }

  @override
  Future<void> salvarRascunho(RascunhoLocal rascunho) async {
    // Handled by DraftRepository
  }
}
