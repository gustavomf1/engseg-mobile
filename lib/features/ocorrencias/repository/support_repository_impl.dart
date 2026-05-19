import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/usuario_summary.dart';
import '../model/localizacao.dart';
import '../model/norma.dart';
import '../model/estabelecimento.dart';
import 'support_repository.dart';
import '../../../core/network/dio_client.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepositoryImpl(dio: ref.watch(dioProvider));
});

final usuariosProvider = FutureProvider.family<List<UsuarioSummary>, String>(
  (ref, estabelecimentoId) async {
    return ref.read(supportRepositoryProvider).listarUsuarios(estabelecimentoId);
  },
);

final localizacoesProvider = FutureProvider.family<List<Localizacao>, String>(
  (ref, estabelecimentoId) async {
    return ref.read(supportRepositoryProvider).listarLocalizacoes(estabelecimentoId);
  },
);

final normasProvider = FutureProvider<List<Norma>>((ref) {
  return ref.read(supportRepositoryProvider).listarNormas();
});

final estabelecimentosProvider = FutureProvider<List<Estabelecimento>>((ref) {
  return ref.read(supportRepositoryProvider).listarEstabelecimentos();
});

class SupportRepositoryImpl implements SupportRepository {
  final Dio dio;

  SupportRepositoryImpl({required this.dio});

  @override
  Future<List<UsuarioSummary>> listarUsuarios(String estabelecimentoId) async {
    final response = await dio.get<List<dynamic>>(
      '/api/usuarios',
      queryParameters: {'estabelecimentoId': estabelecimentoId},
    );
    return (response.data ?? [])
        .map((e) => UsuarioSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Localizacao>> listarLocalizacoes(String estabelecimentoId) async {
    final response = await dio.get<List<dynamic>>(
      '/api/localizacoes',
      queryParameters: {'estabelecimentoId': estabelecimentoId},
    );
    return (response.data ?? [])
        .map((e) => Localizacao.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Norma>> listarNormas() async {
    final response = await dio.get<List<dynamic>>('/api/normas');
    return (response.data ?? [])
        .map((e) => Norma.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Estabelecimento>> listarEstabelecimentos() async {
    final response = await dio.get<List<dynamic>>('/api/estabelecimentos');
    return (response.data ?? [])
        .map((e) => Estabelecimento.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
