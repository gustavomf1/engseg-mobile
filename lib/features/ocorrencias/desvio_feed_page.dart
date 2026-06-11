import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/data/mock_data.dart';
import '../../shared/widgets/prototype_ui.dart';
import '../auth/provider/auth_provider.dart';
import 'model/desvio_summary.dart';
import 'repository/desvio_repository_impl.dart';

class DesvioFeedPage extends ConsumerWidget {
  const DesvioFeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).valueOrNull;
    final isExterno = session?.perfil == 'EXTERNO';
    final workspace = ref.watch(workspaceProvider);
    final workspaceId = workspace?.estabelecimento.id;
    final providerKey = isExterno ? null : workspaceId;
    final async = (isExterno || workspaceId != null)
        ? ref.watch(desvioListProvider(providerKey)).whenData(
              (list) => isExterno
                  ? list.where((d) => d.responsavelTratativaId == session?.id).toList()
                  : list,
            )
        : const AsyncData<List<DesvioSummary>>([]);

    return Scaffold(
      backgroundColor: ProtoColors.bg,
      appBar: AppBar(
        backgroundColor: ProtoColors.bg,
        foregroundColor: ProtoColors.text,
        title: const Text('Desvios'),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: ProtoColors.blue,
          backgroundColor: const Color(0xFF1A2233),
          onRefresh: () async {
            if (isExterno || workspaceId != null) {
              ref.invalidate(desvioListProvider(providerKey));
              await ref
                  .read(desvioListProvider(providerKey).future)
                  .catchError((_) => <DesvioSummary>[]);
            }
          },
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Erro ao carregar: $e',
                  style: const TextStyle(color: ProtoColors.red, fontSize: 13)),
            ),
            data: (list) => list.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 80),
                    Center(
                        child: Text('Nenhum desvio encontrado',
                            style: TextStyle(color: ProtoColors.muted))),
                  ])
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 104),
                    children: list.map((d) => _DesvioCard(d: d)).toList(),
                  ),
          ),
        ),
      ),
    );
  }
}

class _DesvioCard extends StatelessWidget {
  final DesvioSummary d;
  const _DesvioCard({required this.d});

  Color _statusBg() => switch (d.status) {
    'CONCLUIDA' || 'FECHADA' => const Color(0xFF0B3A1C),
    'EM_AJUSTE_PELO_EXTERNO' || 'NAO_RESOLVIDA' => const Color(0xFF4A1017),
    'EM_EXECUCAO' => const Color(0xFF2A164A),
    'AGUARDANDO_VALIDACAO_FINAL' => const Color(0xFF12204A),
    _ => const Color(0xFF0A2A4A),
  };

  Color _statusFg() => switch (d.status) {
    'CONCLUIDA' || 'FECHADA' => ProtoColors.green,
    'EM_AJUSTE_PELO_EXTERNO' || 'NAO_RESOLVIDA' => ProtoColors.red,
    'EM_EXECUCAO' => const Color(0xFFD2A8FF),
    'AGUARDANDO_VALIDACAO_FINAL' => const Color(0xFF93C5FD),
    _ => ProtoColors.blue,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/desvio/${d.id}'),
        child: ProtoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 6, runSpacing: 4, children: [
                const ProtoPill(
                    label: 'Desvio',
                    bg: Color(0xFF4A390A),
                    fg: ProtoColors.yellow),
                ProtoPill(
                  label: statusLabel[d.status] ?? d.status,
                  bg: _statusBg(),
                  fg: _statusFg(),
                ),
              ]),
              const SizedBox(height: 8),
              Text(d.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: ProtoColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.place_outlined,
                    size: 12, color: ProtoColors.muted2),
                const SizedBox(width: 4),
                Flexible(
                    child: Text(d.estabelecimentoNome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: ProtoColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700))),
                const SizedBox(width: 10),
                const Icon(Icons.schedule_rounded,
                    size: 12, color: ProtoColors.muted2),
                const SizedBox(width: 4),
                Text(d.dataRegistro,
                    style: const TextStyle(
                        color: ProtoColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
