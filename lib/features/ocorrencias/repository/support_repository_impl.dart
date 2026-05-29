import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/usuario_summary.dart';
import '../model/localizacao.dart';
import '../model/norma.dart';
import '../model/estabelecimento.dart';
import '../model/empresa.dart';
import '../model/dashboard_stats.dart';
import 'support_repository.dart';
import '../../../core/network/dio_client.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepositoryImpl(dio: ref.watch(dioProvider));
});

final usuariosProvider = FutureProvider.family<List<UsuarioSummary>, String>(
  (ref, estabelecimentoId) async {
    return ref.watch(supportRepositoryProvider).listarUsuarios(estabelecimentoId);
  },
);

/// Busca usuários por empresaId — usado para listar EXTERNO/ENGENHEIRO da empresa filha
final usuariosPorEmpresaProvider = FutureProvider.family<List<UsuarioSummary>, String>(
  (ref, empresaId) async {
    final dio = ref.watch(dioProvider);
    final response = await dio.get<List<dynamic>>(
      '/api/usuarios',
      queryParameters: {'empresaId': empresaId},
    );
    return (response.data ?? [])
        .map((e) => UsuarioSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  },
);

final localizacoesProvider = FutureProvider.family<List<Localizacao>, String>(
  (ref, estabelecimentoId) async {
    return ref.watch(supportRepositoryProvider).listarLocalizacoes(estabelecimentoId);
  },
);

final normasProvider = FutureProvider<List<Norma>>((ref) {
  return ref.watch(supportRepositoryProvider).listarNormas();
});

final estabelecimentosProvider = FutureProvider<List<Estabelecimento>>((ref) {
  return ref.watch(supportRepositoryProvider).listarEstabelecimentos();
});

final empresasMaeProvider = FutureProvider<List<Empresa>>((ref) {
  return ref.watch(supportRepositoryProvider).listarEmpresasMae();
});

final empresasDoEstabelecimentoProvider =
    FutureProvider.family<List<Empresa>, String>((ref, estabelecimentoId) {
  return ref.watch(supportRepositoryProvider).listarEmpresasDoEstabelecimento(estabelecimentoId);
});

final dashboardProvider = FutureProvider.family<DashboardStats, String>(
  (ref, estabelecimentoId) async {
    final dio = ref.watch(dioProvider);
    final response = await dio.get<Map<String, dynamic>>(
      '/api/dashboard/estabelecimento/$estabelecimentoId',
    );
    return DashboardStats.fromJson(response.data!);
  },
);

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
    final response = await dio.get<List<dynamic>>(
      '/api/estabelecimentos',
      queryParameters: {'ativo': true},
    );
    return (response.data ?? [])
        .map((e) => Estabelecimento.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Empresa>> listarEmpresasMae() async {
    final response = await dio.get<List<dynamic>>(
      '/api/empresas',
      queryParameters: {'empresaMae': true, 'ativo': true, 'exibirNoSeletor': true},
    );
    return (response.data ?? [])
        .map((e) => Empresa.fromJson(e as Map<String, dynamic>))
        .where((e) => e.exibirNoSeletor)
        .toList();
  }

  @override
  Future<List<Empresa>> listarEmpresasDoEstabelecimento(String estabelecimentoId) async {
    final response = await dio.get<List<dynamic>>('/api/estabelecimentos/$estabelecimentoId/empresas');
    return (response.data ?? [])
        .map((e) => Empresa.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
