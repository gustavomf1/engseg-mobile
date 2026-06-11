import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/prototype_ui.dart';

class NotifPage extends StatefulWidget {
  const NotifPage({super.key});

  @override
  State<NotifPage> createState() => _NotifPageState();
}

class _NotifPageState extends State<NotifPage> {
  String filter = 'Todas';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProtoColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 104),
          children: [
            Align(alignment: Alignment.centerRight, child: ProtoIconButton(icon: Icons.notifications_none_rounded, onTap: () {})),
            const SizedBox(height: 8),
            const Text('Notificacoes', style: TextStyle(color: ProtoColors.text, fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
            const SizedBox(height: 4),
            const Text('2 nao lidas', style: TextStyle(color: ProtoColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Todas', 'Atribuicoes', 'Prazos', 'Aprovacoes'].map((label) {
                  final selected = label == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => setState(() => filter = label),
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: selected ? const Color(0xFFEAF2FA) : ProtoColors.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: ProtoColors.border)),
                        child: Text(label, style: TextStyle(color: selected ? ProtoColors.bg : ProtoColors.muted, fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            const _DayLabel('Hoje'),
            _NotifItem(color: ProtoColors.red, icon: Icons.shield_outlined, title: 'NC-2026-0287 atribuida a voce', body: '"Trabalho em altura sem ancoragem dupla..." - Refinaria Paulinia · Carla Mendes', time: '14:32', unread: true, onTap: () => context.push('/oc/NC-2026-0287')),
            _NotifItem(color: ProtoColors.yellow, icon: Icons.schedule_rounded, title: 'NC-2026-0282 vence em 2 dias', body: 'Tratativa pendente de validacao final pelo engenheiro responsavel.', time: '11:08', unread: true, onTap: () => context.push('/oc/NC-2026-0282')),
            _NotifItem(color: ProtoColors.green, icon: Icons.done_all_rounded, title: 'Plano de acao aprovado', body: 'NC-2026-0279 - andaime liberado por Felipe Tanaka as 09:14.', time: '09:15', onTap: () => context.push('/oc/NC-2026-0279')),
            const SizedBox(height: 6),
            const _DayLabel('Ontem'),
            _NotifItem(color: ProtoColors.red, icon: Icons.close_rounded, title: 'Plano rejeitado - NC-2026-0274', body: 'Eng. responsavel solicitou inclusao de barreira fisica antes da liberacao.', time: '17:42', onTap: () {}),
            _NotifItem(color: ProtoColors.blue, icon: Icons.chat_bubble_outline_rounded, title: 'Renata Lima comentou em DS-2026-0921', body: '"Ja solicitamos os EPIs corretos ao almoxarifado..."', time: '15:10', onTap: () {}),
          ],
        ),
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  final String label;

  const _DayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
      child: Text(label.toUpperCase(), style: const TextStyle(color: ProtoColors.muted, fontSize: 11, letterSpacing: .6, fontWeight: FontWeight.w900)),
    );
  }
}

class _NotifItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String body;
  final String time;
  final bool unread;
  final VoidCallback onTap;

  const _NotifItem({required this.color, required this.icon, required this.title, required this.body, required this.time, required this.onTap, this.unread = false});

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
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: .18), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ProtoColors.text, fontSize: 13, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ProtoColors.muted, fontSize: 12, height: 1.25)),
                        const SizedBox(height: 4),
                        Text(time, style: const TextStyle(color: ProtoColors.muted2, fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: ProtoColors.muted, size: 18),
                ],
              ),
            ),
          ),
          if (unread)
            Positioned(
              left: -5,
              top: 20,
              child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: ProtoColors.blue, shape: BoxShape.circle)),
            ),
        ],
      ),
    );
  }
}
