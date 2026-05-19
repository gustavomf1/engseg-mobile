import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/provider/auth_provider.dart';
import '../../features/ocorrencias/model/dashboard_stats.dart';
import '../../features/ocorrencias/repository/support_repository_impl.dart';
import '../../shared/widgets/prototype_ui.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(workspaceProvider);
    final AsyncValue<DashboardStats?> statsAsync = workspaceId != null
        ? ref.watch(dashboardProvider(workspaceId)).whenData((s) => s as DashboardStats?)
        : const AsyncData(null);

    return Scaffold(
      backgroundColor: ProtoColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 104),
          children: [
            Row(
              children: [
                const Expanded(child: ProtoStatusBar()),
                ProtoIconButton(icon: Icons.notifications_none_rounded, onTap: () {}),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Dashboard', style: TextStyle(color: ProtoColors.text, fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
            const SizedBox(height: 4),
            const Text('EngSeg · Seguranca do Trabalho', style: TextStyle(color: ProtoColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF315CFF), Color(0xFF8A2CFF)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('RESUMO GERAL', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 10),
            statsAsync.when(
              loading: () => const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.38,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: const [
                  _KpiCard(label: 'VENCIDAS', value: '--', delta: 'Erro ao carregar', color: ProtoColors.red, icon: Icons.error_outline_rounded),
                  _KpiCard(label: 'NCS ABERTAS', value: '--', delta: 'Erro ao carregar', color: ProtoColors.yellow, icon: Icons.schedule_rounded),
                  _KpiCard(label: 'TOTAL NCS', value: '--', delta: 'Erro ao carregar', color: Color(0xFF8A2CFF), icon: Icons.handyman_outlined),
                  _KpiCard(label: 'DESVIOS ABERTOS', value: '--', delta: 'Erro ao carregar', color: ProtoColors.blue, icon: Icons.phone_iphone_rounded),
                ],
              ),
              data: (stats) => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.38,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _KpiCard(
                    label: 'VENCIDAS',
                    value: stats != null ? '${stats.ncsVencidas}' : '--',
                    delta: 'NCs com prazo vencido',
                    color: ProtoColors.red,
                    icon: Icons.error_outline_rounded,
                  ),
                  _KpiCard(
                    label: 'NCS ABERTAS',
                    value: stats != null ? '${stats.ncsAbertas}' : '--',
                    delta: 'Em andamento',
                    color: ProtoColors.yellow,
                    icon: Icons.schedule_rounded,
                  ),
                  _KpiCard(
                    label: 'TOTAL NCS',
                    value: stats != null ? '${stats.totalNcs}' : '--',
                    delta: 'No estabelecimento',
                    color: const Color(0xFF8A2CFF),
                    icon: Icons.handyman_outlined,
                  ),
                  _KpiCard(
                    label: 'DESVIOS ABERTOS',
                    value: stats != null ? '${stats.desviosAbertos}' : '--',
                    delta: 'De ${stats != null ? stats.totalDesvios : "--"} total',
                    color: ProtoColors.blue,
                    icon: Icons.phone_iphone_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const ProtoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProtoSectionTitle('Por estabelecimento'),
                  SizedBox(height: 12),
                  _BarRow(label: 'Refinaria Paulinia', value: '6', pct: .75, color: ProtoColors.red),
                  _BarRow(label: 'Planta Cubatao', value: '4', pct: .50, color: ProtoColors.orange),
                  _BarRow(label: 'Terminal Santos', value: '3', pct: .38, color: ProtoColors.yellow),
                  _BarRow(label: 'CD Guarulhos', value: '1', pct: .13, color: ProtoColors.green),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const ProtoCard(
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(width: 80, height: 80, child: CircularProgressIndicator(value: .68, strokeWidth: 7, color: ProtoColors.orange, backgroundColor: ProtoColors.surface2)),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('68', style: TextStyle(color: ProtoColors.text, fontSize: 24, fontWeight: FontWeight.w900)),
                            Text('DE 100', style: TextStyle(color: ProtoColors.muted, fontSize: 9, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProtoSectionTitle('Risco medio · 30d'),
                        SizedBox(height: 18),
                        Text('Risco Alto', style: TextStyle(color: ProtoColors.orange, fontSize: 13, fontWeight: FontWeight.w900)),
                        SizedBox(height: 4),
                        Text('Score medio ponderado das NCs ativas.\nAumento de 8% vs periodo anterior.', style: TextStyle(color: ProtoColors.muted, fontSize: 11, height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final Color color;
  final IconData icon;

  const _KpiCard({required this.label, required this.value, required this.delta, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ProtoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(color: ProtoColors.muted, fontSize: 11, fontWeight: FontWeight.w900))),
              Container(width: 26, height: 26, decoration: BoxDecoration(color: color.withValues(alpha: .16), shape: BoxShape.circle), child: Icon(icon, color: color, size: 14)),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(color: ProtoColors.text, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(delta, style: const TextStyle(color: ProtoColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final String value;
  final double pct;
  final Color color;

  const _BarRow({required this.label, required this.value, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(children: [Expanded(child: Text(label, style: const TextStyle(color: ProtoColors.text, fontSize: 13, fontWeight: FontWeight.w700))), Text(value, style: const TextStyle(color: ProtoColors.muted, fontSize: 12))]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: pct, minHeight: 5, color: color, backgroundColor: ProtoColors.surface2),
          ),
        ],
      ),
    );
  }
}
