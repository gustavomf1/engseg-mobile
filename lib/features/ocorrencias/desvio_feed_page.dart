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
    final workspaceId = ref.watch(workspaceProvider)?.estabelecimento.id;
    final async = workspaceId != null
        ? ref.watch(desvioListProvider(workspaceId))
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
            if (workspaceId != null) {
              ref.invalidate(desvioListProvider(workspaceId));
              await ref
                  .read(desvioListProvider(workspaceId).future)
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
                  bg: ProtoColors.surface2,
                  fg: ProtoColors.blue,
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
