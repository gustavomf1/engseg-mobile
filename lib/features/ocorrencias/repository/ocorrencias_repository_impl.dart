import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/ocorrencia_summary.dart';
import 'ocorrencias_repository.dart';
import '../../../core/network/dio_client.dart';

// Provider key: (estabelecimentoId, meuPapel)
final ocorrenciasProvider =
    FutureProvider.family<List<OcorrenciaSummary>, (String?, String?)>(
  (ref, args) async {
    final (estabelecimentoId, meuPapel) = args;
    return ref
        .read(ocorrenciasRepositoryProvider)
        .listar(estabelecimentoId: estabelecimentoId, meuPapel: meuPapel);
  },
);

final ocorrenciasRepositoryProvider = Provider<OcorrenciasRepository>((ref) {
  return OcorrenciasRepositoryImpl(dio: ref.watch(dioProvider));
});

class OcorrenciasRepositoryImpl implements OcorrenciasRepository {
  final Dio dio;
  OcorrenciasRepositoryImpl({required this.dio});

  @override
  Future<List<OcorrenciaSummary>> listar({
    String? estabelecimentoId,
    String? meuPapel,
  }) async {
    final response = await dio.get<List<dynamic>>(
      '/api/ocorrencias',
      queryParameters: {
        if (estabelecimentoId != null) 'estabelecimentoId': estabelecimentoId,
        if (meuPapel != null) 'meuPapel': meuPapel,
      },
    );
    return (response.data ?? [])
        .map((e) => OcorrenciaSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
