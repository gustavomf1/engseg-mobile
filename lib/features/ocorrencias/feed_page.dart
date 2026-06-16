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

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  String _filter = 'todas';

  void _setFilter(String v) => setState(() => _filter = v);

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider).valueOrNull;
    final isExterno = session?.perfil == 'EXTERNO';
    final workspace = ref.watch(workspaceProvider);
    final workspaceId = workspace?.estabelecimento.id;

    final (String?, String?) providerKey = isExterno
        ? (null, 'RESPONSAVEL_TRATATIVA_NC')
        : (workspaceId, null);

    final ncsAsync = (isExterno || workspaceId != null)
        ? ref.watch(ocorrenciasProvider(providerKey)).whenData(
              (list) => list.where((o) => o.isNc).toList(),
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 104),
            children: [
              ncsAsync.when(
                loading: () => _filterRow([], 0, 0, 0, 0),
                error: (_, __) => _filterRow([], 0, 0, 0, 0),
                data: (ncs) {
                  final todas = ncs.length;
                  final abertas =
                      ncs.where((n) => n.status == 'ABERTA').length;
                  final vencidas = ncs.where((n) => n.vencida).length;
                  final concluidas = ncs
                      .where((n) =>
                          n.status == 'CONCLUIDA' || n.status == 'FECHADA')
                      .length;
                  return _filterRow(ncs, todas, abertas, vencidas, concluidas);
                },
              ),
              const SizedBox(height: 12),
              ncsAsync.when(
                loading: () => Column(
                  children:
                      List.generate(3, (_) => const CoverCardSkeleton()),
                ),
                error: (e, _) => _ErrorState(message: '$e'),
                data: (ncs) {
                  final filtered = _applyFilter(ncs);
                  if (filtered.isEmpty) {
                    return const _EmptyState(message: 'Nenhuma NC encontrada');
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < filtered.length; i++)
                        _buildCard(filtered[i]).staggered(i),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<OcorrenciaSummary> _applyFilter(List<OcorrenciaSummary> ncs) {
    return switch (_filter) {
      'abertas' => ncs.where((n) => n.status == 'ABERTA').toList(),
      'vencidas' => ncs.where((n) => n.vencida).toList(),
      'concluidas' => ncs
          .where((n) => n.status == 'CONCLUIDA' || n.status == 'FECHADA')
          .toList(),
      _ => ncs,
    };
  }

  Widget _buildCard(OcorrenciaSummary nc) {
    final ncColors = StatusColorHelper.ncColors(nc.status, vencida: nc.vencida);
    final coverUrl = nc.primeiraEvidenciaId != null
        ? '${AppConfig.apiBaseUrl}/api/evidencias/${nc.primeiraEvidenciaId}/download'
        : null;

    return EngCoverCard(
      id: nc.id,
      titulo: nc.titulo,
      coverUrl: coverUrl,
      hasImageCover: nc.hasImageCover,
      hasAnyCover: nc.hasAnyCover,
      pills: [
        const EngPill(
          label: 'NC',
          bg: Color(0xFF4A1017),
          fg: Color(0xFFFF4D4D),
        ),
        EngPill(
          label: StatusColorHelper.ncLabel(nc.status),
          bg: ncColors.bg,
          fg: ncColors.fg,
        ),
        if (nc.vencida)
          const EngPill(
            label: 'Vencida',
            bg: Color(0xFF4A1017),
            fg: Color(0xFFFF4D4D),
          ),
      ],
      meta: '${nc.estabelecimentoNome} · ${nc.nivelRisco ?? ''}',
      onTap: () => context.push('/oc/${nc.id}'),
    );
  }

  Widget _filterRow(List<OcorrenciaSummary> ncs, int todas, int abertas,
      int vencidas, int concluidas) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(label: 'Todas', value: 'todas', count: todas, active: _filter == 'todas', onTap: _setFilter),
          _Chip(label: 'Abertas', value: 'abertas', count: abertas, active: _filter == 'abertas', onTap: _setFilter),
          _Chip(label: 'Vencidas', value: 'vencidas', count: vencidas, active: _filter == 'vencidas', onTap: _setFilter),
          _Chip(label: 'Concluídas', value: 'concluidas', count: concluidas, active: _filter == 'concluidas', onTap: _setFilter),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final int count;
  final bool active;
  final void Function(String) onTap;

  const _Chip({required this.label, required this.value, required this.count, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(EngSegRadius.pill),
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: EngSegMotion.fast,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: active ? EngSegColors.dark.accent.withValues(alpha: 0.15) : EngSegColors.dark.bgSurface,
            borderRadius: BorderRadius.circular(EngSegRadius.pill),
            border: Border.all(
              color: active ? EngSegColors.dark.accent : EngSegColors.dark.borderSoft,
            ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: active ? EngSegColors.dark.accent : EngSegColors.dark.fg2,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: EngSegColors.dark.bgElevated,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(color: EngSegColors.dark.fg2, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: EngSegColors.dark.fg3),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: EngSegColors.dark.fg2, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: EngSegColors.dark.statusRedFg),
          const SizedBox(height: 12),
          Text('Erro ao carregar', style: TextStyle(color: EngSegColors.dark.statusRedFg, fontSize: 14)),
          const SizedBox(height: 4),
          Text(message, style: TextStyle(color: EngSegColors.dark.fg3, fontSize: 12)),
        ],
      ),
    );
  }
}
