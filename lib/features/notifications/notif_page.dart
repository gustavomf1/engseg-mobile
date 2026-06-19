import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/prototype_ui.dart';
import 'model/notificacao_item.dart';
import 'repository/notificacao_repository_impl.dart';

class NotifPage extends ConsumerWidget {
  const NotifPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificacoesAsync = ref.watch(notificacoesProvider);
    final naoLidas = notificacoesAsync.valueOrNull?.where((n) => !n.lida).length ?? 0;

    return Scaffold(
      backgroundColor: ProtoColors.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: ProtoColors.blue,
          onRefresh: () async {
            ref.invalidate(notificacoesProvider);
            await ref.read(notificacoesProvider.future).catchError((_) => <NotificacaoItem>[]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 104),
            children: [
              Align(alignment: Alignment.centerRight, child: ProtoIconButton(icon: Icons.notifications_none_rounded, onTap: () {})),
              const SizedBox(height: 8),
              const Text('Notificacoes', style: TextStyle(color: ProtoColors.text, fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
              const SizedBox(height: 4),
              Text('$naoLidas nao lidas', style: const TextStyle(color: ProtoColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),
              notificacoesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('Erro ao carregar notificações', style: TextStyle(color: ProtoColors.muted))),
                ),
                data: (notificacoes) {
                  if (notificacoes.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('Nenhuma notificação por aqui', style: TextStyle(color: ProtoColors.muted))),
                    );
                  }
                  return Column(
                    children: [
                      for (final n in notificacoes)
                        _NotifItem(
                          item: n,
                          onTap: () async {
                            if (!n.lida) {
                              await ref.read(notificacaoRepositoryProvider).marcarComoLida(n.id);
                              ref.invalidate(notificacoesProvider);
                            }
                            if (context.mounted) context.push('/oc/${n.ncId}');
                          },
                        ),
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
}

class _NotifItem extends StatelessWidget {
  final NotificacaoItem item;
  final VoidCallback onTap;

  const _NotifItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: ProtoCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: ProtoColors.blue.withValues(alpha: .18), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.shield_outlined, color: ProtoColors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.titulo, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ProtoColors.text, fontSize: 13, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(item.corpo, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ProtoColors.muted, fontSize: 12, height: 1.25)),
                        const SizedBox(height: 4),
                        Text(_formatTime(item.criadoEm), style: const TextStyle(color: ProtoColors.muted2, fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: ProtoColors.muted, size: 18),
                ],
              ),
            ),
          ),
          if (!item.lida)
            Positioned(
              left: -5,
              top: 20,
              child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: ProtoColors.blue, shape: BoxShape.circle)),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
