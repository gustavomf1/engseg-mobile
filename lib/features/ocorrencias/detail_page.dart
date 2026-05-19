import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/data/mock_data.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/widgets/status_widgets.dart';

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

class DetailPage extends StatelessWidget {
  final String id;

  const DetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final oc = mockOcorrencias.firstWhere((item) => item.id == id, orElse: () => mockOcorrencias.first);
    final tone = oc.vencida ? 'red' : (oc.concluida ? 'green' : statusTone[oc.status] ?? 'blue');

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: _NcDetailColors.bg,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              _DetailHero(oc: oc, tone: tone),
              _DetailTabs(oc: oc),
              Expanded(
                child: TabBarView(
                  children: [
                    _GeralTab(oc: oc),
                    _EvidenciasTab(oc: oc),
                    _PlanoTab(concluida: oc.concluida),
                    _HistoricoTab(oc: oc),
                  ],
                ),
              ),
              if (!oc.concluida) _DetailActions(status: oc.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  final MockOcorrencia oc;
  final String tone;

  const _DetailHero({required this.oc, required this.tone});

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
              StatusPill(label: oc.tipo, tone: oc.tipo == 'NC' ? 'red' : 'yellow', mini: true),
              StatusPill(label: statusLabel[oc.status] ?? oc.status, tone: tone, mini: true),
              if (oc.origemMobile) const StatusPill(label: 'Mobile', tone: 'blue', icon: Icons.smartphone_rounded, mini: true),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            oc.titulo,
            style: const TextStyle(color: _NcDetailColors.text, fontSize: 22, fontWeight: FontWeight.w900, height: 1.08),
            // Force the NC detail palette from the approved prototype.
            // This screen intentionally does not inherit the app theme.
            // ignore: deprecated_member_use
            textScaler: TextScaler.noScaling,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _HeroMeta(icon: Icons.tag_rounded, label: oc.id),
              _HeroMeta(icon: Icons.place_outlined, label: oc.estabelecimento),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailTabs extends StatelessWidget {
  final MockOcorrencia oc;

  const _DetailTabs({required this.oc});

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
          Tab(child: Text('Evidencias ·\n4', textAlign: TextAlign.center)),
          Tab(child: Text('Plano de\nAcao · 3', textAlign: TextAlign.center)),
          Tab(text: 'Historico'),
        ],
      ),
    );
  }
}

class _GeralTab extends StatelessWidget {
  final MockOcorrencia oc;

  const _GeralTab({required this.oc});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: [
        const _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('Descricao'),
              SizedBox(height: 8),
              Text(
                'Durante inspecao de rotina no bloco C, equipe de manutencao foi flagrada executando atividade em altura (~6.5m) com apenas um ponto de ancoragem, em desacordo com o procedimento POP-35.04 da unidade. A atividade foi imediatamente interrompida.',
                style: TextStyle(color: _NcDetailColors.text, fontSize: 13, height: 1.55),
              ),
            ],
          ),
        ),
        if (oc.tipo == 'NC') ...[
          const SizedBox(height: 12),
          _DarkCard(
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _NcDetailColors.red,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: _NcDetailColors.red.withValues(alpha: .44), offset: const Offset(0, 9), blurRadius: 22, spreadRadius: -5)],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('SCORE', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800)),
                      Text('20', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RISCO CRITICO', style: TextStyle(color: _NcDetailColors.red, fontSize: 13, fontWeight: FontWeight.w900)),
                      SizedBox(height: 4),
                      Text('Severidade 5 - Catastrofica\nProbabilidade 4 - Provavel', style: TextStyle(color: _NcDetailColors.text, fontSize: 12, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Responsaveis'),
              const SizedBox(height: 8),
              const _KvRow(label: 'Engenheiro responsavel', value: 'Felipe Tanaka'),
              const _KvRow(label: 'Tratativa', value: 'Marcos Silva (terceiro)'),
              _KvRow(label: 'Criada por', value: oc.autor),
              const _KvRow(label: 'Data limite', value: '13/05/2026', valueColor: _NcDetailColors.red),
            ],
          ),
        ),
        if (oc.origemMobile) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _NcDetailColors.surface,
              borderRadius: BorderRadius.circular(EngSegRadius.md),
              border: const Border(left: BorderSide(color: _NcDetailColors.blue, width: 3), top: BorderSide(color: _NcDetailColors.border), right: BorderSide(color: _NcDetailColors.border), bottom: BorderSide(color: _NcDetailColors.border)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CAPTURA MOBILE', style: TextStyle(color: _NcDetailColors.blue, fontSize: 13, letterSpacing: .3, fontWeight: FontWeight.w900)),
                SizedBox(height: 8),
                _KvRow(label: 'Localizacao', value: '-22.7260, -47.1486', mono: true),
                _KvRow(label: 'Horario (BRT)', value: '14h32 - 06/05/2026'),
                _KvRow(label: 'Dispositivo', value: 'iPhone - Carla M.'),
              ],
            ),
          ),
        ],
        if (oc.normas.isNotEmpty) ...[
          const SizedBox(height: 12),
          _DarkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Normas violadas'),
                const SizedBox(height: 10),
                for (final norma in oc.normas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: _NcDetailColors.surface2, borderRadius: BorderRadius.circular(10), border: Border.all(color: _NcDetailColors.border)),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: const Color(0xFF4A1017), borderRadius: BorderRadius.circular(8)),
                            child: Text(norma.replaceAll('-', ''), style: const TextStyle(color: Color(0xFFFF5A5F), fontSize: 11, fontWeight: FontWeight.w900)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(norma, style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, fontWeight: FontWeight.w900)),
                                Text(_normaLabel(norma), style: const TextStyle(color: _NcDetailColors.muted, fontSize: 11)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: _NcDetailColors.muted),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _normaLabel(String norma) {
    return switch (norma) {
      'NR-35' => 'Trabalho em altura - item 35.5.1',
      'NR-06' => 'EPI - item 6.3',
      'NR-33' => 'Espaco confinado - item 33.3',
      _ => 'Norma aplicavel',
    };
  }
}

class _EvidenciasTab extends StatelessWidget {
  final MockOcorrencia oc;

  const _EvidenciasTab({required this.oc});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: [
        _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('4 evidencias fotograficas'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 4 / 3,
                children: List.generate(4, (index) => _EvidenceTile(index: index, mobile: oc.origemMobile)),
              ),
              if (oc.origemMobile) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF0D2747), borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_rounded, size: 14, color: _NcDetailColors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Foto tirada em -22.7260, -47.1486\n14h32 - 06/05/2026 (Horario de Brasilia)',
                          style: TextStyle(color: _NcDetailColors.blue, fontSize: 12, height: 1.35, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
      ('Substituir cinturao tipo paraquedista por modelo de duplo talabarte', 'Marcos Silva', '08/05', true),
      ('Treinamento NR-35 reciclagem para a equipe (3h)', 'Renata Lima', '10/05', false),
      ('Auditar 100% dos pontos de ancoragem do bloco C', 'Felipe Tanaka', '13/05', false),
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
  final MockOcorrencia oc;

  const _HistoricoTab({required this.oc});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Carla Mendes', 'Registro criado via mobile - 4 fotos com GPS', '06/05/2026 - 14:32'),
      ('Felipe Tanaka', 'Responsavel atribuido para verificacao', '06/05/2026 - 15:02'),
      ('Sistema', 'Notificacoes enviadas aos responsaveis', '06/05/2026 - 15:03'),
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
  final bool mobile;

  const _EvidenceTile({required this.index, required this.mobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: index.isEven ? _NcDetailColors.surface2 : _NcDetailColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _NcDetailColors.border),
      ),
      child: Stack(
        children: [
          const Center(child: Icon(Icons.image_rounded, color: _NcDetailColors.muted)),
          if (mobile)
            Positioned(
              left: 6,
              right: 6,
              bottom: 6,
              child: Row(
                children: [
                  const Icon(Icons.place_rounded, size: 10, color: Colors.white),
                  const SizedBox(width: 3),
                  const Text('GPS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text('14h3${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
        ],
      ),
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
