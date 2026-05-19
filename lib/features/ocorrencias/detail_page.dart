import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/status_widgets.dart';
import 'model/nc_detail.dart';
import 'repository/nc_repository_impl.dart';

class _NcDetailColors {
  static const bg = Color(0xFF0B1118);
  static const hero = Color(0xFF1A2534);
  static const surface = Color(0xFF151A21);
  static const surface2 = Color(0xFF1A2028);
  static const border = Color(0xFF26303B);
  static const borderStrong = Color(0xFF748195);
  static const text = Color(0xFFF8FBFF);
  static const muted = Color(0xFF566170);
  static const muted2 = Color(0xFF3F4A57);
  static const blue = Color(0xFF58A6FF);
  static const red = Color(0xFFFF4D4D);
  static const green = Color(0xFF3FB950);
}

final _ncDetailProvider = FutureProvider.family<NcDetail, String>((ref, id) {
  return ref.read(ncRepositoryProvider).buscarPorId(id);
});

class DetailPage extends ConsumerWidget {
  final String id;

  const DetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ncAsync = ref.watch(_ncDetailProvider(id));

    return ncAsync.when(
      loading: () => Scaffold(
        backgroundColor: _NcDetailColors.bg,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: _NcDetailColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              const _FakeStatusBar(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _HeroIconButton(icon: Icons.chevron_left_rounded, onTap: () => context.pop()),
                  ],
                ),
              ),
              const Spacer(),
              Icon(Icons.error_outline_rounded, color: _NcDetailColors.red, size: 48),
              const SizedBox(height: 12),
              Text('Erro ao carregar NC', style: const TextStyle(color: _NcDetailColors.text, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('$err', style: const TextStyle(color: _NcDetailColors.muted, fontSize: 12), textAlign: TextAlign.center),
              const Spacer(),
            ],
          ),
        ),
      ),
      data: (nc) {
        final risco = nc.nivelRisco.toUpperCase();
        final tone = risco == 'CRITICO'
            ? 'red'
            : risco == 'ALTO'
                ? 'red'
                : risco == 'MEDIO'
                    ? 'yellow'
                    : 'blue';
        final concluida = nc.status == 'CONCLUIDA' || nc.status == 'FECHADA';

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            backgroundColor: _NcDetailColors.bg,
            body: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: [
                  _DetailHero(nc: nc, tone: tone),
                  _DetailTabs(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _GeralTab(nc: nc),
                        _EvidenciasTab(),
                        _PlanoTab(concluida: concluida),
                        _HistoricoTab(nc: nc),
                      ],
                    ),
                  ),
                  if (!concluida) _DetailActions(status: nc.status),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailHero extends StatelessWidget {
  final NcDetail nc;
  final String tone;

  const _DetailHero({required this.nc, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
      decoration: const BoxDecoration(
        color: _NcDetailColors.hero,
        border: Border(bottom: BorderSide(color: _NcDetailColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FakeStatusBar(),
          const SizedBox(height: 12),
          Row(
            children: [
              _HeroIconButton(icon: Icons.chevron_left_rounded, onTap: () => context.pop()),
              const Spacer(),
              _HeroIconButton(icon: Icons.share_rounded, onTap: () {}),
              const SizedBox(width: 8),
              _HeroIconButton(icon: Icons.more_vert_rounded, onTap: () {}),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              const StatusPill(label: 'NC', tone: 'red', mini: true),
              StatusPill(label: nc.status, tone: tone, mini: true),
              if (nc.regraDeOuro) const StatusPill(label: 'Regra de Ouro', tone: 'red', mini: true),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            nc.titulo,
            style: const TextStyle(color: _NcDetailColors.text, fontSize: 22, fontWeight: FontWeight.w900, height: 1.08),
            // ignore: deprecated_member_use
            textScaler: TextScaler.noScaling,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _HeroMeta(icon: Icons.tag_rounded, label: nc.id),
              _HeroMeta(icon: Icons.place_outlined, label: nc.estabelecimentoNome),
              if (nc.localizacaoNome != null)
                _HeroMeta(icon: Icons.map_outlined, label: nc.localizacaoNome!),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailTabs extends StatelessWidget {
  const _DetailTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        color: _NcDetailColors.surface,
        border: Border(bottom: BorderSide(color: _NcDetailColors.border)),
      ),
      child: const TabBar(
        labelColor: _NcDetailColors.text,
        unselectedLabelColor: _NcDetailColors.muted,
        indicatorColor: _NcDetailColors.blue,
        indicatorWeight: 2,
        indicatorPadding: EdgeInsets.symmetric(horizontal: 14),
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        unselectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        tabs: [
          Tab(text: 'Geral'),
          Tab(child: Text('Evidencias', textAlign: TextAlign.center)),
          Tab(child: Text('Plano de\nAcao', textAlign: TextAlign.center)),
          Tab(text: 'Historico'),
        ],
      ),
    );
  }
}

class _GeralTab extends StatelessWidget {
  final NcDetail nc;

  const _GeralTab({required this.nc});

  String _nivelRiscoLabel(String nivel) {
    return switch (nivel.toUpperCase()) {
      'CRITICO' => 'RISCO CRITICO',
      'ALTO' => 'RISCO ALTO',
      'MEDIO' => 'RISCO MEDIO',
      _ => 'RISCO BAIXO',
    };
  }

  Color _nivelRiscoColor(String nivel) {
    return switch (nivel.toUpperCase()) {
      'CRITICO' => _NcDetailColors.red,
      'ALTO' => const Color(0xFFFF8C42),
      'MEDIO' => const Color(0xFFFFBB33),
      _ => _NcDetailColors.green,
    };
  }

  @override
  Widget build(BuildContext context) {
    final riscoColor = _nivelRiscoColor(nc.nivelRisco);
    final score = nc.severidade * nc.probabilidade;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: [
        _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Descricao'),
              const SizedBox(height: 8),
              Text(
                nc.descricao ?? 'Sem descricao disponivel.',
                style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, height: 1.55),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _DarkCard(
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: riscoColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: riscoColor.withValues(alpha: .44), offset: const Offset(0, 9), blurRadius: 22, spreadRadius: -5)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('SCORE', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800)),
                    Text('$score', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_nivelRiscoLabel(nc.nivelRisco), style: TextStyle(color: riscoColor, fontSize: 13, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('Severidade ${nc.severidade}\nProbabilidade ${nc.probabilidade}', style: const TextStyle(color: _NcDetailColors.text, fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Responsaveis'),
              const SizedBox(height: 8),
              _KvRow(label: 'Criada por', value: nc.usuarioCriacaoNome),
              _KvRow(label: 'Registro', value: nc.dataRegistro),
              if (nc.dataLimiteResolucao != null)
                _KvRow(label: 'Data limite', value: nc.dataLimiteResolucao!, valueColor: _NcDetailColors.red),
              if (nc.reincidencia)
                const _KvRow(label: 'Reincidencia', value: 'Sim', valueColor: _NcDetailColors.red),
            ],
          ),
        ),
      ],
    );
  }
}

class _EvidenciasTab extends StatelessWidget {
  const _EvidenciasTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: [
        _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Evidencias fotograficas'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 4 / 3,
                children: List.generate(4, (index) => _EvidenceTile(index: index)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanoTab extends StatelessWidget {
  final bool concluida;

  const _PlanoTab({required this.concluida});

  @override
  Widget build(BuildContext context) {
    final actions = [
      ('Verificar conformidade com procedimentos internos', 'Responsavel', '—', false),
      ('Elaborar plano de acao corretivo', 'Engenheiro', '—', false),
      ('Validar resolucao e fechar NC', 'Responsavel', '—', false),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: [
        _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Plano de Acao - 5W2H'),
              const SizedBox(height: 12),
              for (var i = 0; i < actions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: actions[i].$4 ? const Color(0xFF15281F) : _NcDetailColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _NcDetailColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: actions[i].$4 ? _NcDetailColors.green : (i == 1 ? _NcDetailColors.blue : _NcDetailColors.surface2),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: actions[i].$4 ? const Icon(Icons.check_rounded, color: Colors.white, size: 13) : Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(actions[i].$1, style: TextStyle(color: _NcDetailColors.text, fontSize: 13, fontWeight: FontWeight.w800, height: 1.35, decoration: actions[i].$4 ? TextDecoration.lineThrough : null)),
                              const SizedBox(height: 4),
                              Text('${actions[i].$2} - ate ${actions[i].$3}', style: const TextStyle(color: _NcDetailColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoricoTab extends StatelessWidget {
  final NcDetail nc;

  const _HistoricoTab({required this.nc});

  @override
  Widget build(BuildContext context) {
    final items = [
      (nc.usuarioCriacaoNome, 'Registro criado', nc.dataRegistro),
      ('Sistema', 'Notificacoes enviadas aos responsaveis', nc.dataRegistro),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: [
        _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Linha do tempo'),
              const SizedBox(height: 12),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 10, height: 10, margin: const EdgeInsets.only(top: 4), decoration: const BoxDecoration(color: _NcDetailColors.blue, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.$1, style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, fontWeight: FontWeight.w900)),
                            Text(item.$2, style: const TextStyle(color: _NcDetailColors.muted, fontSize: 12, height: 1.35)),
                            Text(item.$3, style: const TextStyle(color: _NcDetailColors.muted2, fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailActions extends StatelessWidget {
  final String status;

  const _DetailActions({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(color: _NcDetailColors.surface, border: Border(top: BorderSide(color: _NcDetailColors.border))),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _NcDetailColors.text,
                backgroundColor: _NcDetailColors.surface2,
                side: const BorderSide(color: _NcDetailColors.border),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {},
              icon: const Icon(Icons.message_rounded, size: 16),
              label: const Text('Comentar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _NcDetailColors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {},
              icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
              label: Text(status == 'ABERTA' ? 'Submeter plano' : 'Atualizar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  final int index;

  const _EvidenceTile({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: index.isEven ? _NcDetailColors.surface2 : _NcDetailColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _NcDetailColors.border),
      ),
      child: const Center(child: Icon(Icons.image_rounded, color: _NcDetailColors.muted)),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeroIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: _NcDetailColors.borderStrong)),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: _NcDetailColors.text),
      ),
    );
  }
}

class _FakeStatusBar extends StatelessWidget {
  const _FakeStatusBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          const SizedBox(width: 34),
          const Text('9:41', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
          const Spacer(),
          Container(
            width: 136,
            height: 38,
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(24)),
          ),
          const Spacer(),
          const Icon(Icons.signal_cellular_alt_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 4),
          const Icon(Icons.wifi_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 5),
          const Icon(Icons.battery_full_rounded, color: Colors.white, size: 20),
        ],
      ),
    );
  }
}

class _DarkCard extends StatelessWidget {
  final Widget child;

  const _DarkCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _NcDetailColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _NcDetailColors.border),
      ),
      child: child,
    );
  }
}

class _HeroMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroMeta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _NcDetailColors.muted),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _NcDetailColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(), style: const TextStyle(color: Color(0xFFD7E8FF), fontSize: 13, letterSpacing: .45, fontWeight: FontWeight.w900));
  }
}

class _KvRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool mono;

  const _KvRow({required this.label, required this.value, this.valueColor, this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: _NcDetailColors.muted, fontSize: 12, fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(color: valueColor ?? _NcDetailColors.text, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: mono ? 'monospace' : null),
            ),
          ),
        ],
      ),
    );
  }
}
