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

// ── Workflow action helpers ────────────────────────────────────────────────
Future<NcDetail> ativarNc(Dio dio, String ncId) async {
  final r = await dio.post<Map<String, dynamic>>('/api/nao-conformidades/$ncId/ativar');
  return NcDetail.fromJson(r.data!);
}

Future<NcDetail> submeterInvestigacao(Dio dio, String ncId, Map<String, dynamic> payload) async {
  final r = await dio.post<Map<String, dynamic>>('/api/nao-conformidades/$ncId/investigacao', data: payload);
  return NcDetail.fromJson(r.data!);
}

Future<NcDetail> aprovarPlano(Dio dio, String ncId) async {
  final r = await dio.post<Map<String, dynamic>>('/api/nao-conformidades/$ncId/aprovar-plano');
  return NcDetail.fromJson(r.data!);
}

Future<NcDetail> rejeitarPlano(Dio dio, String ncId, String motivo) async {
  final r = await dio.post<Map<String, dynamic>>('/api/nao-conformidades/$ncId/rejeitar-plano', data: {'motivo': motivo});
  return NcDetail.fromJson(r.data!);
}

Future<NcDetail> submeterExecucao(Dio dio, String ncId, List<Map<String, dynamic>> atividades) async {
  final r = await dio.post<Map<String, dynamic>>('/api/nao-conformidades/$ncId/submeter-execucao', data: {'atividades': atividades});
  return NcDetail.fromJson(r.data!);
}

Future<NcDetail> aprovarEvidencias(Dio dio, String ncId) async {
  final r = await dio.post<Map<String, dynamic>>('/api/nao-conformidades/$ncId/aprovar-evidencias');
  return NcDetail.fromJson(r.data!);
}

Future<NcDetail> rejeitarEvidencias(Dio dio, String ncId, String motivo) async {
  final r = await dio.post<Map<String, dynamic>>('/api/nao-conformidades/$ncId/rejeitar-evidencias', data: {'motivo': motivo});
  return NcDetail.fromJson(r.data!);
}

Future<NcDetail> revisarAtividades(Dio dio, String ncId, List<Map<String, dynamic>> decisoes, {String? comentario, bool porqueRejeitado = false}) async {
  final r = await dio.post<Map<String, dynamic>>(
    '/api/nao-conformidades/$ncId/revisar-atividades',
    data: {
      'decisoes': decisoes,
      if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
      'porqueRejeitado': porqueRejeitado,
    },
  );
  return NcDetail.fromJson(r.data!);
}

Future<NcDetail> revisarExecucao(Dio dio, String ncId, List<Map<String, dynamic>> decisoes, {String? comentario}) async {
  final r = await dio.post<Map<String, dynamic>>(
    '/api/nao-conformidades/$ncId/revisar-execucao',
    data: {
      'decisoes': decisoes,
      if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
    },
  );
  return NcDetail.fromJson(r.data!);
}

final evidenciasNcProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, ncId) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get<List<dynamic>>('/api/evidencias/nao-conformidade/$ncId');
  return (r.data ?? []).cast<Map<String, dynamic>>();
});

final ncListProvider = FutureProvider.family<List<NcSummary>, String?>(
  (ref, estabelecimentoId) async {
    return ref.watch(ncRepositoryProvider).listar(
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
