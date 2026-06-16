import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/widgets/eng_cover_card.dart';
import '../../shared/widgets/eng_pill.dart';
import '../../shared/widgets/eng_skeleton.dart';
import '../../shared/widgets/motion_helpers.dart';
import '../../shared/widgets/status_color_helper.dart';
import '../auth/provider/auth_provider.dart';
import 'model/ocorrencia_summary.dart';
import 'repository/ocorrencias_repository_impl.dart';

class DesvioFeedPage extends ConsumerWidget {
  const DesvioFeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).valueOrNull;
    final isExterno = session?.perfil == 'EXTERNO';
    final workspace = ref.watch(workspaceProvider);
    final workspaceId = workspace?.estabelecimento.id;

    final (String?, String?) providerKey = isExterno
        ? (null, 'RESPONSAVEL_TRATATIVA_DESVIO')
        : (workspaceId, null);

    final desviosAsync = (isExterno || workspaceId != null)
        ? ref.watch(ocorrenciasProvider(providerKey)).whenData(
              (list) => list.where((o) => o.isDesvio).toList(),
            )
        : const AsyncData<List<OcorrenciaSummary>>([]);

    return Scaffold(
      backgroundColor: EngSegColors.dark.bgBase,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: EngSegColors.dark.accent,
          backgroundColor: EngSegColors.dark.bgElevated,
          onRefresh: () async {
            ref.invalidate(ocorrenciasProvider(providerKey));
            await ref
                .read(ocorrenciasProvider(providerKey).future)
                .catchError((_) => <OcorrenciaSummary>[]);
          },
          child: desviosAsync.when(
            loading: () => ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 104),
              children: List.generate(3, (_) => const CoverCardSkeleton()),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: EngSegColors.dark.statusRedFg),
                    const SizedBox(height: 12),
                    Text('Erro ao carregar',
                        style: TextStyle(
                            color: EngSegColors.dark.statusRedFg,
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('$e',
                        style: TextStyle(
                            color: EngSegColors.dark.fg3, fontSize: 12)),
                  ],
                ),
              ),
            ),
            data: (list) => list.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(16, 80, 16, 104),
                    children: [
                      Column(
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 48, color: EngSegColors.dark.fg3),
                          const SizedBox(height: 12),
                          Text('Nenhum desvio encontrado',
                              style: TextStyle(
                                  color: EngSegColors.dark.fg2, fontSize: 14)),
                        ],
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 104),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final dv = list[i];
                      final dvColors =
                          StatusColorHelper.desvioColors(dv.status);
                      final coverUrl = dv.primeiraEvidenciaId != null
                          ? '${AppConfig.apiBaseUrl}/api/evidencias/${dv.primeiraEvidenciaId}/download'
                          : null;
                      return EngCoverCard(
                        id: dv.id,
                        titulo: dv.titulo,
                        coverUrl: coverUrl,
                        hasImageCover: dv.hasImageCover,
                        hasAnyCover: dv.hasAnyCover,
                        pills: [
                          EngPill(
                            label: 'Desvio',
                            bg: EngSegColors.dark.statusYellowBg,
                            fg: EngSegColors.dark.statusYellowFg,
                          ),
                          EngPill(
                            label: StatusColorHelper.desvioLabel(dv.status),
                            bg: dvColors.bg,
                            fg: dvColors.fg,
                          ),
                        ],
                        meta:
                            '${dv.estabelecimentoNome} · ${dv.dataRegistro}',
                        onTap: () => context.push('/desvio/${dv.id}'),
                      ).staggered(i);
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
