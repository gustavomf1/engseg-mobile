import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/data/mock_data.dart';
import '../../shared/widgets/prototype_ui.dart';
import '../auth/provider/auth_provider.dart';
import 'model/nc_summary.dart';
import 'repository/nc_repository_impl.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  String filter = 'todas';

  @override
  Widget build(BuildContext context) {
    final workspaceId = ref.watch(workspaceProvider);
    final ncsAsync = workspaceId != null
        ? ref.watch(ncListProvider(workspaceId))
        : const AsyncData<List<NcSummary>>([]);

    return Scaffold(
      backgroundColor: ProtoColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 104),
          children: [
            const ProtoStatusBar(),
            const SizedBox(height: 12),
            const _PushBanner(),
            const SizedBox(height: 12),
            ncsAsync.when(
              loading: () => Row(
                children: [
                  _FilterChip(label: 'Todas', value: 'todas', count: 0, active: filter == 'todas', onTap: _setFilter),
                ],
              ),
              error: (_, __) => Row(
                children: [
                  _FilterChip(label: 'Todas', value: 'todas', count: 0, active: filter == 'todas', onTap: _setFilter),
                ],
              ),
              data: (ncs) {
                final todas = ncs.length;
                final abertas = ncs.where((n) => n.status == 'ABERTA').length;
                final vencidas = ncs.where((n) => n.vencida).length;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(label: 'Todas', value: 'todas', count: todas, active: filter == 'todas', onTap: _setFilter),
                      _FilterChip(label: 'Abertas', value: 'abertas', count: abertas, active: filter == 'abertas', onTap: _setFilter),
                      _FilterChip(label: 'Vencidas', value: 'vencidas', count: vencidas, active: filter == 'vencidas', onTap: _setFilter),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            ncsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Erro ao carregar: $e',
                  style: const TextStyle(color: ProtoColors.red, fontSize: 13),
                ),
              ),
              data: (ncs) {
                final list = ncs.where((nc) {
                  return switch (filter) {
                    'abertas' => nc.status == 'ABERTA',
                    'vencidas' => nc.vencida,
                    _ => true,
                  };
                }).toList();
                if (list.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Nenhuma NC encontrada',
                        style: TextStyle(color: ProtoColors.muted, fontSize: 13),
                      ),
                    ),
                  );
                }
                return Column(
                  children: list.map((nc) => _NcCard(nc: nc)).toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            const Center(child: Text('fim da lista', style: TextStyle(color: ProtoColors.muted2, fontSize: 11))),
          ],
        ),
      ),
    );
  }

  void _setFilter(String value) => setState(() => filter = value);
}

class _PushBanner extends StatelessWidget {
  const _PushBanner();

  @override
  Widget build(BuildContext context) {
    return ProtoCard(
      color: ProtoColors.surface,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: ProtoColors.purple, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.shield_outlined, color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ENGSEG', style: TextStyle(color: ProtoColors.muted, fontSize: 10, fontWeight: FontWeight.w900)),
                SizedBox(height: 3),
                Text('NC-2026-0287 atribuida a voce', style: TextStyle(color: ProtoColors.text, fontSize: 13, fontWeight: FontWeight.w900)),
                SizedBox(height: 2),
                Text('"Trabalho em altura sem ancoragem dupla..." - Refinaria Paulinia', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: ProtoColors.muted, fontSize: 12)),
              ],
            ),
          ),
          const Text('agora', style: TextStyle(color: ProtoColors.muted2, fontSize: 10)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final int count;
  final bool active;
  final ValueChanged<String> onTap;

  const _FilterChip({required this.label, required this.value, required this.count, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(color: active ? const Color(0xFFEAF2FA) : ProtoColors.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: ProtoColors.border)),
          child: Row(
            children: [
              Text(label, style: TextStyle(color: active ? ProtoColors.bg : ProtoColors.muted, fontSize: 12, fontWeight: FontWeight.w900)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: active ? Colors.white.withValues(alpha: .5) : ProtoColors.surface2, borderRadius: BorderRadius.circular(99)),
                child: Text('$count', style: TextStyle(color: active ? ProtoColors.text : ProtoColors.muted, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NcCard extends StatelessWidget {
  final NcSummary nc;

  const _NcCard({required this.nc});

  @override
  Widget build(BuildContext context) {
    final isRed = nc.vencida || nc.nivelRisco == 'CRITICO' || nc.nivelRisco == 'ALTO';
    final color = isRed ? ProtoColors.red : ProtoColors.yellow;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go('/oc/${nc.id}'),
        child: ProtoCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.shield_outlined, color: color, size: 28),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        const ProtoPill(label: 'NC', bg: Color(0xFF4A1017), fg: ProtoColors.red),
                        ProtoPill(
                          label: statusLabel[nc.status] ?? nc.status,
                          bg: _statusBg(),
                          fg: _statusFg(),
                        ),
                        if (nc.vencida)
                          const ProtoPill(label: 'Vencida', bg: Color(0xFF4A1017), fg: ProtoColors.red),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(nc.titulo, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ProtoColors.text, fontSize: 15, height: 1.18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 7),
                    _MetaLine(icon: Icons.tag_rounded, label: nc.id, secondIcon: Icons.place_outlined, second: nc.estabelecimentoNome),
                    const SizedBox(height: 5),
                    _MetaLine(icon: Icons.schedule_rounded, label: nc.dataRegistro, secondIcon: Icons.bar_chart_rounded, second: nc.nivelRisco),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusBg() {
    if (nc.vencida) return const Color(0xFF4A1017);
    if (nc.status == 'CONCLUIDO') return const Color(0xFF0B3A1C);
    if (nc.status == 'EM_EXECUCAO') return const Color(0xFF2A164A);
    return const Color(0xFF4A390A);
  }

  Color _statusFg() {
    if (nc.vencida) return ProtoColors.red;
    if (nc.status == 'CONCLUIDO') return ProtoColors.green;
    if (nc.status == 'EM_EXECUCAO') return const Color(0xFFD2A8FF);
    return ProtoColors.yellow;
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final IconData secondIcon;
  final String second;

  const _MetaLine({required this.icon, required this.label, required this.secondIcon, required this.second});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 11, color: ProtoColors.muted2),
        const SizedBox(width: 3),
        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ProtoColors.muted, fontSize: 11, fontWeight: FontWeight.w700))),
        const SizedBox(width: 9),
        Icon(secondIcon, size: 11, color: ProtoColors.muted2),
        const SizedBox(width: 3),
        Flexible(child: Text(second, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ProtoColors.muted, fontSize: 11, fontWeight: FontWeight.w700))),
      ],
    );
  }
}
