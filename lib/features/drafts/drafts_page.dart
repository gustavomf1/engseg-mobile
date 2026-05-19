import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ocorrencias/model/rascunho_local.dart';
import '../../features/ocorrencias/repository/draft_repository_impl.dart';
import '../../shared/widgets/prototype_ui.dart';

class DraftsPage extends ConsumerWidget {
  const DraftsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftsAsync = ref.watch(draftsProvider);

    return Scaffold(
      backgroundColor: ProtoColors.bg,
      body: SafeArea(
        bottom: false,
        child: draftsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro: $e', style: const TextStyle(color: ProtoColors.red))),
          data: (drafts) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 104),
            children: [
              Row(children: [const Expanded(child: ProtoStatusBar()), ProtoIconButton(icon: Icons.notifications_none_rounded, onTap: () {})]),
              const SizedBox(height: 8),
              const Text('Rascunhos', style: TextStyle(color: ProtoColors.text, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text('${drafts.length} pendentes de sincronizacao', style: const TextStyle(color: ProtoColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              ProtoCard(
                color: const Color(0xFF132B20),
                child: Row(
                  children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: ProtoColors.green, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.cloud_sync_rounded, color: Colors.white)),
                    const SizedBox(width: 12),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Os rascunhos serao enviados automaticamente.', style: TextStyle(color: ProtoColors.text, fontWeight: FontWeight.w900)), SizedBox(height: 3), Text('Sincronizacao automatica ao conectar.', style: TextStyle(color: ProtoColors.muted, fontSize: 11))])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFEAF2FA), borderRadius: BorderRadius.circular(8)), child: const Text('Forcar', style: TextStyle(color: ProtoColors.bg, fontSize: 11, fontWeight: FontWeight.w900))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final draft in drafts) _DraftCard(draft: draft),
              const SizedBox(height: 10),
              const ProtoCard(
                color: Color(0xFF111820),
                child: Center(child: Text('Rascunhos ficam no dispositivo ate serem publicados.', style: TextStyle(color: ProtoColors.muted2, fontSize: 11))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  final RascunhoLocal draft;
  const _DraftCard({required this.draft});

  @override
  Widget build(BuildContext context) {
    final isNc = draft.tipo == 'NC';
    final synced = draft.sincronizado == 1;
    final color = synced ? ProtoColors.green : (isNc ? ProtoColors.red : ProtoColors.yellow);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ProtoCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(12)), child: Icon(isNc ? Icons.shield_outlined : Icons.warning_amber_rounded, color: color, size: 23)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 6, children: [
                    ProtoPill(label: draft.tipo, bg: isNc ? const Color(0xFF4A1017) : const Color(0xFF4A390A), fg: isNc ? ProtoColors.red : ProtoColors.yellow),
                    ProtoPill(label: synced ? 'Sincronizado' : 'Pendente', bg: color.withValues(alpha: .16), fg: color),
                  ]),
                  const SizedBox(height: 6),
                  Text(draft.titulo, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ProtoColors.text, fontSize: 13, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text(draft.descricao ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ProtoColors.muted, fontSize: 10, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
