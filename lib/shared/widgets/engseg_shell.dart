import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/provider/auth_provider.dart';
import 'prototype_ui.dart';

class EngSegShell extends ConsumerWidget {
  final Widget child;

  const EngSegShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(authProvider).valueOrNull?.perfil;
    final isExterno = perfil == 'EXTERNO';
    return Scaffold(
      backgroundColor: ProtoColors.bg,
      body: child,
      floatingActionButtonLocation: isExterno ? null : FloatingActionButtonLocation.centerDocked,
      floatingActionButton: isExterno
          ? null
          : Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ProtoColors.purple,
                border: Border.all(color: ProtoColors.blue, width: 2),
                boxShadow: [BoxShadow(color: ProtoColors.blue.withValues(alpha: .35), blurRadius: 16, spreadRadius: 2)],
              ),
              child: IconButton(
                onPressed: () => _showChooseTipo(context),
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 31),
              ),
            ),
      bottomNavigationBar: Container(
        height: 84,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 18),
        decoration: const BoxDecoration(color: ProtoColors.surface, border: Border(top: BorderSide(color: ProtoColors.border))),
        child: const Row(
          children: [
            _NavItem(path: '/feed', icon: Icons.shield_outlined, label: 'NCs'),
            _NavItem(path: '/desvios', icon: Icons.local_fire_department_outlined, label: 'Desvios'),
            Expanded(child: SizedBox()),
            _NavItem(path: '/notif', icon: Icons.notifications_none_rounded, label: 'Avisos'),
            _NavItem(path: '/profile', icon: Icons.person_outline_rounded, label: 'Perfil'),
          ],
        ),
      ),
    );
  }

  void _showChooseTipo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ProtoColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProtoSectionTitle('Registrar ocorrencia'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TipoCard(
                    title: 'NC',
                    subtitle: 'Nao conformidade',
                    color: ProtoColors.red,
                    icon: Icons.shield_outlined,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.go('/camera?tipo=nc');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TipoCard(
                    title: 'Desvio',
                    subtitle: 'Condicao insegura',
                    color: ProtoColors.yellow,
                    icon: Icons.local_fire_department_outlined,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.go('/camera?tipo=desvio');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String path;
  final IconData icon;
  final String label;

  const _NavItem({required this.path, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final selected = GoRouterState.of(context).uri.path == path;
    final color = selected ? ProtoColors.blue : ProtoColors.muted;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go(path),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 26 : 0,
              height: 3,
              decoration: BoxDecoration(color: ProtoColors.blue, borderRadius: BorderRadius.circular(999)),
            ),
            const SizedBox(height: 12),
            Icon(icon, size: 21, color: color),
            const SizedBox(height: 2),
            Text(label, maxLines: 1, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _TipoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _TipoCard({required this.title, required this.subtitle, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: ProtoCard(
        color: color.withValues(alpha: .10),
        child: SizedBox(
          height: 122,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 40, color: color),
              const Spacer(),
              Text(title, style: const TextStyle(color: ProtoColors.text, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: ProtoColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
