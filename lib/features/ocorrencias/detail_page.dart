import 'dart:io';

import 'package:dio/dio.dart' as dio_pkg;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/config/app_config.dart';
import '../../core/network/dio_client.dart';
import '../../features/auth/model/login_response.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../../shared/widgets/status_widgets.dart';
import 'model/nc_detail.dart';
import 'repository/nc_repository_impl.dart';

// ── Date helpers ────────────────────────────────────────────────────────────
String _fmtDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    // Pure date YYYY-MM-DD — parse directly to avoid timezone issues
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(iso);
    if (m != null) return '${m.group(3)}/${m.group(2)}/${m.group(1)}';
    final dt = DateTime.parse(iso);
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
  } catch (_) { return iso; }
}

String _fmtDateTime(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    final utc = DateTime.parse(iso.contains('Z') ? iso : '${iso}Z');
    final br = utc.subtract(const Duration(hours: 3));
    return '${br.day.toString().padLeft(2,'0')}/${br.month.toString().padLeft(2,'0')}/${br.year} ${br.hour.toString().padLeft(2,'0')}:${br.minute.toString().padLeft(2,'0')}';
  } catch (_) { return iso; }
}

// ── JWT token provider ───────────────────────────────────────────────────────
final _jwtTokenProvider = FutureProvider<String?>((ref) async {
  const storage = FlutterSecureStorage();
  return storage.read(key: 'jwt_token');
});

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
  static const yellow = Color(0xFFD4A017);
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
          length: 5,
          child: Scaffold(
            backgroundColor: _NcDetailColors.bg,
            body: SafeArea(
              top: true,
              bottom: false,
              child: Column(
                children: [
                  _DetailHero(nc: nc, tone: tone),
                  _DetailTabs(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _GeralTab(nc: nc),
                        _EvidenciasTab(ncId: nc.id),
                        _PlanoTab(nc: nc, concluida: concluida),
                        _ExecucaoTab(nc: nc),
                        _HistoricoTab(nc: nc),
                      ],
                    ),
                  ),
                  _DetailActions(nc: nc, user: ref.watch(authProvider).valueOrNull),
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
              if (nc.vencida) const StatusPill(label: 'Vencida', tone: 'red', mini: true),
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
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: _NcDetailColors.text,
        unselectedLabelColor: _NcDetailColors.muted,
        indicatorColor: _NcDetailColors.blue,
        indicatorWeight: 2,
        indicatorPadding: EdgeInsets.symmetric(horizontal: 14),
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        unselectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        tabs: [
          Tab(text: 'Geral'),
          Tab(child: Text('Evidências', textAlign: TextAlign.center)),
          Tab(child: Text('Plano de\nAção', textAlign: TextAlign.center)),
          Tab(text: 'Execução'),
          Tab(text: 'Histórico'),
        ],
      ),
    );
  }
}

class _GeralTab extends StatelessWidget {
  final NcDetail nc;
  const _GeralTab({required this.nc});

  static Color _riscoColor(String nivel) => switch (nivel.toUpperCase()) {
    'CRITICO' => _NcDetailColors.red,
    'ALTO'    => const Color(0xFFFF8C42),
    'MEDIO'   => const Color(0xFFFFBB33),
    _         => _NcDetailColors.green,
  };

  static String _riscoLabel(String nivel) => switch (nivel.toUpperCase()) {
    'CRITICO' => 'CRÍTICO',
    'ALTO'    => 'ALTO',
    'MEDIO'   => 'MÉDIO',
    _         => 'BAIXO',
  };

  static Color _cellColor(int sev, int prob) {
    final s = sev * prob;
    if (s >= 13) return const Color(0xFFFF4D4D);
    if (s >= 9)  return const Color(0xFFFF8C42);
    if (s >= 5)  return const Color(0xFFFFBB33);
    return const Color(0xFF3FB950);
  }

  @override
  Widget build(BuildContext context) {
    final riscoColor = _riscoColor(nc.nivelRisco);
    final score = nc.severidade * nc.probabilidade;

    // Prazo
    int? diasRestantes;
    int? diasVencidos;
    if (nc.dataLimiteResolucao != null) {
      try {
        final prazo = DateTime.parse(nc.dataLimiteResolucao!);
        final diff = prazo.difference(DateTime.now()).inDays;
        if (diff < 0) diasVencidos = -diff; else diasRestantes = diff;
      } catch (_) {}
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        // ── Identificação ─────────────────────────────────────────────────
        _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Identificação'),
              const SizedBox(height: 12),
              _KvRow(label: 'Estabelecimento', value: nc.estabelecimentoNome),
              if (nc.localizacaoNome != null && nc.localizacaoNome!.isNotEmpty)
                _KvRow(label: 'Localização', value: nc.localizacaoNome!),
              _KvRow(label: 'Data de Registro', value: _fmtDateTime(nc.dataRegistro)),
              if (nc.dataLimiteResolucao != null)
                _KvRow(
                  label: 'Data Limite',
                  value: _fmtDate(nc.dataLimiteResolucao),
                  valueColor: nc.vencida ? _NcDetailColors.red : null,
                ),
              _KvRow(label: 'Registrado por', value: nc.usuarioCriacaoNome),
              if (nc.usuarioCriacaoEmail != null)
                _KvRow(label: '', value: nc.usuarioCriacaoEmail!, valueColor: _NcDetailColors.muted),
              if (nc.regraDeOuro)
                const _KvRow(label: 'Regra de Ouro', value: 'Sim', valueColor: _NcDetailColors.red),
              if (nc.reincidencia) ...[
                const _KvRow(label: 'Reincidência', value: 'Sim', valueColor: _NcDetailColors.red),
                if (nc.ncAnteriorId != null && nc.ncAnteriorTitulo != null)
                  GestureDetector(
                    onTap: () => context.push('/oc/${nc.ncAnteriorId}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 110,
                            child: Text('NC de Origem', style: TextStyle(color: _NcDetailColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(child: Text(nc.ncAnteriorTitulo!, style: const TextStyle(color: _NcDetailColors.blue, fontSize: 12, fontWeight: FontWeight.w700))),
                                const SizedBox(width: 4),
                                const Icon(Icons.open_in_new_rounded, size: 13, color: _NcDetailColors.blue),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              if (nc.descricao != null && nc.descricao!.isNotEmpty) ...[
                const SizedBox(height: 10),
                const _SectionTitle('Descrição'),
                const SizedBox(height: 6),
                Text(nc.descricao!, style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, height: 1.55)),
              ],
              if (nc.normas.isNotEmpty) ...[
                const SizedBox(height: 12),
                const _SectionTitle('Normas Vinculadas'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: nc.normas.map((n) => _NormaBadge(norma: n)).toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Responsáveis ──────────────────────────────────────────────────
        if (nc.responsavelTrativaNome != null || nc.responsavelNcNome != null)
          _DarkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Responsáveis'),
                const SizedBox(height: 12),
                if (nc.responsavelTrativaNome != null)
                  _ResponsavelRow(
                    perfil: nc.responsavelTrativaPerfil ?? 'EXTERNO',
                    nome: nc.responsavelTrativaNome!,
                    email: nc.responsavelTrativaEmail,
                  ),
                if (nc.responsavelTrativaNome != null && nc.responsavelNcNome != null)
                  const SizedBox(height: 10),
                if (nc.responsavelNcNome != null)
                  _ResponsavelRow(
                    perfil: nc.responsavelNcPerfil ?? 'ENGENHEIRO',
                    nome: nc.responsavelNcNome!,
                    email: nc.responsavelNcEmail,
                  ),
              ],
            ),
          ),
        if (nc.responsavelTrativaNome != null || nc.responsavelNcNome != null)
          const SizedBox(height: 12),

        // ── Prazo ─────────────────────────────────────────────────────────
        if (nc.dataLimiteResolucao != null)
          _DarkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: nc.vencida ? _NcDetailColors.red : _NcDetailColors.muted),
                    const SizedBox(width: 6),
                    const _SectionTitle('Prazo'),
                    const Spacer(),
                    if (diasVencidos != null)
                      Text('${diasVencidos}d vencido', style: const TextStyle(color: _NcDetailColors.red, fontSize: 12, fontWeight: FontWeight.w900))
                    else if (diasRestantes != null)
                      Text('${diasRestantes}d restantes', style: const TextStyle(color: _NcDetailColors.green, fontSize: 12, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: diasVencidos != null ? 1.0 : (diasRestantes != null ? (1 - diasRestantes / 30).clamp(0.0, 1.0) : 0.5),
                    minHeight: 6,
                    color: nc.vencida ? _NcDetailColors.red : _NcDetailColors.blue,
                    backgroundColor: _NcDetailColors.surface2,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Vence em ${_fmtDate(nc.dataLimiteResolucao)}', style: const TextStyle(color: _NcDetailColors.muted, fontSize: 11)),
              ],
            ),
          ),
        if (nc.dataLimiteResolucao != null) const SizedBox(height: 12),

        // ── Análise de Risco ──────────────────────────────────────────────
        _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Análise de Risco'),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Matrix 5x4
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(children: [
                            const SizedBox(width: 18),
                            ...List.generate(5, (s) => Expanded(child: Center(child: Text('${s+1}', style: const TextStyle(color: _NcDetailColors.muted2, fontSize: 9, fontWeight: FontWeight.w900))))),
                          ]),
                        ),
                        ...List.generate(4, (pi) {
                          final p = 4 - pi;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(children: [
                              SizedBox(width: 18, child: Center(child: Text('$p', style: const TextStyle(color: _NcDetailColors.muted2, fontSize: 9, fontWeight: FontWeight.w900)))),
                              ...List.generate(5, (si) {
                                final s = si + 1;
                                final isSelected = s == nc.severidade && p == nc.probabilidade;
                                final c = _cellColor(s, p);
                                return Expanded(
                                  child: Container(
                                    height: 22,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: BoxDecoration(
                                      color: isSelected ? c : c.withValues(alpha: .28),
                                      borderRadius: BorderRadius.circular(3),
                                      border: isSelected ? Border.all(color: Colors.white, width: 1.5) : null,
                                    ),
                                    child: isSelected ? Center(child: Text('${s*p}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900))) : null,
                                  ),
                                );
                              }),
                            ]),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Score box
                  Container(
                    width: 64,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: riscoColor.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: riscoColor.withValues(alpha: .4)),
                    ),
                    child: Column(
                      children: [
                        Text('$score', style: TextStyle(color: riscoColor, fontSize: 26, fontWeight: FontWeight.w900, height: 1)),
                        const SizedBox(height: 2),
                        Text('/20', style: TextStyle(color: riscoColor.withValues(alpha: .6), fontSize: 10, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(_riscoLabel(nc.nivelRisco), style: TextStyle(color: riscoColor, fontSize: 10, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _RiscoMeta(label: 'SEV.', value: '${nc.severidade}', sub: _sevLabel(nc.severidade)),
                  const SizedBox(width: 16),
                  _RiscoMeta(label: 'PROB.', value: '${nc.probabilidade}', sub: _probLabel(nc.probabilidade)),
                  const SizedBox(width: 16),
                  _RiscoMeta(label: 'NÍVEL', value: _riscoLabel(nc.nivelRisco), sub: 'score $score', color: riscoColor),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _sevLabel(int v) => switch (v) { 1 => 'Insignificante', 2 => 'Menor', 3 => 'Moderado', 4 => 'Maior', _ => 'Catastrófico' };
  static String _probLabel(int v) => switch (v) { 1 => 'Improvável', 2 => 'Possível', 3 => 'Provável', _ => 'Quase certo' };
}

class _NormaBadge extends StatelessWidget {
  final Map<String, dynamic> norma;
  const _NormaBadge({required this.norma});

  void _show(BuildContext context) {
    final titulo = norma['titulo'] as String? ?? '—';
    final descricao = norma['descricao'] as String?;
    final conteudo = norma['conteudo'] as String?;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151A21),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: const Color(0xFF3F4A57), borderRadius: BorderRadius.circular(99))),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0xFF1A2534), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF58A6FF).withValues(alpha: .5))),
                        child: Text(titulo, style: const TextStyle(color: Color(0xFF58A6FF), fontSize: 13, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  if (descricao != null && descricao.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text('Descrição', style: const TextStyle(color: Color(0xFFD7E8FF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4)),
                    const SizedBox(height: 6),
                    Text(descricao, style: const TextStyle(color: Color(0xFFF8FBFF), fontSize: 13, height: 1.55)),
                  ],
                  const SizedBox(height: 14),
                  Text('Trecho vinculado', style: const TextStyle(color: Color(0xFFD7E8FF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4)),
                  const SizedBox(height: 6),
                  conteudo != null && conteudo.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF0B1118), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF26303B))),
                          child: Text(conteudo, style: const TextStyle(color: Color(0xFFF8FBFF), fontSize: 13, height: 1.6)),
                        )
                      : const Text('Sem trecho vinculado.', style: TextStyle(color: Color(0xFF566170), fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titulo = norma['titulo'] as String? ?? '—';
    final conteudo = norma['conteudo'] as String?;
    final hasTrecho = conteudo != null && conteudo.isNotEmpty;
    return GestureDetector(
      onTap: () => _show(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2534),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF58A6FF).withValues(alpha: .5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_rounded, size: 13, color: Color(0xFF58A6FF)),
            const SizedBox(width: 5),
            Text(titulo, style: const TextStyle(color: Color(0xFF58A6FF), fontSize: 12, fontWeight: FontWeight.w900)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: hasTrecho ? const Color(0xFF3FB950).withValues(alpha: .2) : const Color(0xFF3F4A57), borderRadius: BorderRadius.circular(99)),
              child: Text(hasTrecho ? 'trecho' : 'sem trecho', style: TextStyle(color: hasTrecho ? const Color(0xFF3FB950) : const Color(0xFF566170), fontSize: 9, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsavelRow extends StatelessWidget {
  final String perfil;
  final String nome;
  final String? email;
  const _ResponsavelRow({required this.perfil, required this.nome, this.email});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _NcDetailColors.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _NcDetailColors.border),
          ),
          child: Text(nome.isNotEmpty ? nome[0].toUpperCase() : '?',
              style: const TextStyle(color: _NcDetailColors.text, fontSize: 14, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(perfil, style: const TextStyle(color: _NcDetailColors.muted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .4)),
              Text(nome, style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, fontWeight: FontWeight.w800)),
              if (email != null) Text(email!, style: const TextStyle(color: _NcDetailColors.muted, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _ConfirmRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: _NcDetailColors.muted2, fontSize: 11, fontWeight: FontWeight.w700))),
          Expanded(child: Text(value, style: TextStyle(color: valueColor ?? _NcDetailColors.text, fontSize: 12, fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _RiscoMeta extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color? color;
  const _RiscoMeta({required this.label, required this.value, required this.sub, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _NcDetailColors.muted2, fontSize: 10, fontWeight: FontWeight.w900)),
        Text(value, style: TextStyle(color: color ?? _NcDetailColors.text, fontSize: 18, fontWeight: FontWeight.w900, height: 1.1)),
        Text(sub, style: const TextStyle(color: _NcDetailColors.muted, fontSize: 10)),
      ],
    );
  }
}

class _EvidenciasTab extends ConsumerWidget {
  final String ncId;
  const _EvidenciasTab({required this.ncId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evidAsync = ref.watch(evidenciasNcProvider(ncId));
    final tokenAsync = ref.watch(_jwtTokenProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: [
        _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Evidências fotográficas'),
              const SizedBox(height: 12),
              evidAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Erro ao carregar: $e', style: const TextStyle(color: _NcDetailColors.red, fontSize: 12)),
                data: (evidencias) {
                  if (evidencias.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('Nenhuma evidência', style: TextStyle(color: _NcDetailColors.muted, fontSize: 13))),
                    );
                  }
                  final token = tokenAsync.valueOrNull;
                  return Column(
                    children: [
                      for (final ev in evidencias)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _EvidenciaCard(ev: ev, token: token),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanoTab extends StatelessWidget {
  final NcDetail nc;
  final bool concluida;
  const _PlanoTab({required this.nc, required this.concluida});

  @override
  Widget build(BuildContext context) {
    final snapshots = nc.investigacaoSnapshots;
    final semPlano = snapshots.isEmpty && nc.porques.isEmpty && nc.causaRaiz == null && nc.atividades.isEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        if (semPlano)
          _DarkCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const Icon(Icons.assignment_late_outlined, color: _NcDetailColors.muted, size: 32),
                  const SizedBox(height: 8),
                  const Text('Nenhum plano de ação submetido ainda.', style: TextStyle(color: _NcDetailColors.muted, fontSize: 13)),
                ],
              ),
            ),
          )
        else ...[
          // Histórico de submissões (snapshots)
          for (var i = 0; i < snapshots.length; i++) ...[
            _SnapshotCard(index: i, snapshot: snapshots[i], ncAtividades: nc.atividades),
            const SizedBox(height: 12),
          ],
          // Plano atual (ativo) se não há snapshots ou se o atual difere do último snapshot
          if (nc.porques.isNotEmpty || (nc.causaRaiz != null && nc.causaRaiz!.isNotEmpty) || nc.atividades.isNotEmpty) ...[
            if (snapshots.isEmpty) ...[
              _DarkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const _SectionTitle('Plano Atual'),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _NcDetailColors.yellow.withValues(alpha: .15), borderRadius: BorderRadius.circular(99), border: Border.all(color: _NcDetailColors.yellow.withValues(alpha: .4))),
                        child: const Text('EM ANÁLISE', style: TextStyle(color: _NcDetailColors.yellow, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    _PorquesSection(porques: nc.porques),
                    if (nc.causaRaiz != null && nc.causaRaiz!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _CausaRaizSection(causaRaiz: nc.causaRaiz!),
                    ],
                    if (nc.atividades.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _AtividadesSection(atividades: nc.atividades),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ],
      ],
    );
  }
}

class _SnapshotCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> snapshot;
  final List<Map<String, dynamic>> ncAtividades;
  const _SnapshotCard({required this.index, required this.snapshot, required this.ncAtividades});

  @override
  State<_SnapshotCard> createState() => _SnapshotCardState();
}

class _SnapshotCardState extends State<_SnapshotCard> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    // Expande automaticamente o mais recente
    _expanded = widget.index == 0;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.snapshot;
    final status = (s['status'] as String? ?? '').toUpperCase();
    final isAprovado = status == 'APROVADO';
    final isReprovado = status == 'REPROVADO';
    final comentario = s['comentarioRevisao'] as String?;
    final dataSubmissao = _fmtDateTime(s['dataSubmissao'] as String?);
    final statusColor = isAprovado ? _NcDetailColors.green : isReprovado ? _NcDetailColors.red : _NcDetailColors.yellow;
    final statusLabel = isAprovado ? 'Aprovado' : isReprovado ? 'Reprovado' : 'Pendente';

    final isPendente = !isAprovado && !isReprovado;
    final porques = _buildPorquesFromSnapshot(s);
    final causaRaiz = s['causaRaiz'] as String?;
    final snapshotAtividades = (s['atividades'] as List<dynamic>? ?? []).cast<String>();

    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header clicável
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Text(
                  'Submissão ${widget.index + 1}',
                  style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: statusColor.withValues(alpha: .4)),
                  ),
                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900)),
                ),
                const Spacer(),
                Text(dataSubmissao, style: const TextStyle(color: _NcDetailColors.muted, fontSize: 11)),
                const SizedBox(width: 6),
                Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: _NcDetailColors.muted, size: 18),
              ],
            ),
          ),
          // Motivo de reprovação sempre visível
          if (isReprovado && comentario != null && comentario.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _NcDetailColors.red.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _NcDetailColors.red.withValues(alpha: .35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cancel_outlined, size: 14, color: _NcDetailColors.red),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Motivo da reprovação', style: TextStyle(color: _NcDetailColors.red, fontSize: 10, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 3),
                        Text(comentario, style: const TextStyle(color: _NcDetailColors.text, fontSize: 12, height: 1.45)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Conteúdo expansível
          if (_expanded) ...[
            const SizedBox(height: 14),
            const Divider(color: _NcDetailColors.border, height: 1),
            const SizedBox(height: 14),
            if (porques.isNotEmpty) _PorquesSection(porques: porques),
            if (causaRaiz != null && causaRaiz.isNotEmpty) ...[
              if (porques.isNotEmpty) const SizedBox(height: 14),
              _CausaRaizSection(causaRaiz: causaRaiz),
            ],
            if ((isPendente && widget.ncAtividades.isNotEmpty) || (!isPendente && snapshotAtividades.isNotEmpty)) ...[
              const SizedBox(height: 14),
              const Text('PLANO DE ATIVIDADES', style: TextStyle(color: Color(0xFFD7E8FF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4)),
              const SizedBox(height: 8),
              if (isPendente)
                for (var i = 0; i < widget.ncAtividades.length; i++) ...[
                  _AtividadeSnapshotCard(index: i, raw: _ncAtividadeToRaw(widget.ncAtividades[i])),
                  const SizedBox(height: 6),
                ]
              else
                for (var i = 0; i < snapshotAtividades.length; i++) ...[
                  _AtividadeSnapshotCard(index: i, raw: snapshotAtividades[i]),
                  const SizedBox(height: 6),
                ],
            ],
          ],
        ],
      ),
    );
  }

  static String _ncAtividadeToRaw(Map<String, dynamic> a) {
    final titulo = a['titulo'] as String? ?? '';
    final descricao = a['descricao'] as String? ?? '';
    final status = (a['status'] as String? ?? 'PENDENTE').toUpperCase();
    final motivo = a['motivoRejeicao'] as String?;
    String suffix;
    if (status == 'APROVADA') suffix = ' || APROVADA';
    else if (status == 'REJEITADA') suffix = motivo != null && motivo.isNotEmpty ? ' || REJEITADA: $motivo' : ' || REJEITADA';
    else suffix = ' || PENDENTE';
    return '$titulo — $descricao$suffix';
  }

  static List<Map<String, dynamic>> _buildPorquesFromSnapshot(Map<String, dynamic> s) {
    const names = ['Um', 'Dois', 'Tres', 'Quatro', 'Cinco'];
    final result = <Map<String, dynamic>>[];
    for (final n in names) {
      final p = s['porque${n[0].toUpperCase()}${n.substring(1)}'] as String? ?? s['porque$n'] as String?;
      final r = s['porque${n[0].toUpperCase()}${n.substring(1)}Resposta'] as String? ?? s['porque${n}Resposta'] as String?;
      if (p != null && p.isNotEmpty) result.add({'pergunta': p, 'resposta': r ?? ''});
    }
    return result;
  }
}

class _PorquesSection extends StatelessWidget {
  final List<Map<String, dynamic>> porques;
  const _PorquesSection({required this.porques});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('5 PORQUÊS', style: TextStyle(color: Color(0xFFD7E8FF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4)),
        const SizedBox(height: 10),
        for (var i = 0; i < porques.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20, height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _NcDetailColors.blue.withValues(alpha: .2), borderRadius: BorderRadius.circular(6)),
                      child: Text('${i+1}', style: const TextStyle(color: _NcDetailColors.blue, fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(porques[i]['pergunta'] as String? ?? '', style: const TextStyle(color: _NcDetailColors.muted, fontSize: 12, fontWeight: FontWeight.w700))),
                  ],
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Text(porques[i]['resposta'] as String? ?? '—', style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, height: 1.4)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CausaRaizSection extends StatelessWidget {
  final String causaRaiz;
  const _CausaRaizSection({required this.causaRaiz});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CAUSA RAIZ', style: TextStyle(color: Color(0xFFD7E8FF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4)),
        const SizedBox(height: 8),
        Text(causaRaiz, style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, height: 1.5)),
      ],
    );
  }
}

class _AtividadeSnapshotCard extends StatelessWidget {
  final int index;
  final String raw;
  const _AtividadeSnapshotCard({required this.index, required this.raw});

  @override
  Widget build(BuildContext context) {
    final sepIdx = raw.lastIndexOf(' || ');
    final content = sepIdx >= 0 ? raw.substring(0, sepIdx) : raw;
    final statusPart = sepIdx >= 0 ? raw.substring(sepIdx + 4) : 'PENDENTE';
    final isRejeitada = statusPart.startsWith('REJEITADA');
    final isAprovada = statusPart == 'APROVADA';
    final isPendente = !isAprovada && !isRejeitada;
    String? motivo;
    if (isRejeitada && statusPart.contains(': ')) {
      motivo = statusPart.substring(statusPart.indexOf(': ') + 2).trim();
    }
    final dashIdx = content.indexOf(' — ');
    final titulo = dashIdx >= 0 ? content.substring(0, dashIdx) : content;
    final descricao = dashIdx >= 0 ? content.substring(dashIdx + 3) : null;

    final color = isRejeitada ? _NcDetailColors.red : isAprovada ? _NcDetailColors.green : _NcDetailColors.yellow;
    final bgColor = isRejeitada ? const Color(0xFF2A1A1A) : isAprovada ? const Color(0xFF0D2318) : _NcDetailColors.surface2;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20, height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(6)),
                child: Text('${index + 1}', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
                    if (descricao != null && descricao.isNotEmpty)
                      Text(descricao, style: const TextStyle(color: _NcDetailColors.muted, fontSize: 11, height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: color.withValues(alpha: .4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isRejeitada ? Icons.cancel_outlined : isPendente ? Icons.hourglass_empty_rounded : Icons.check_circle_outline_rounded, size: 10, color: color),
                    const SizedBox(width: 3),
                    Text(isRejeitada ? 'Rejeitada' : isPendente ? 'Pendente' : 'Aprovada', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
          if (motivo != null && motivo.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
              decoration: BoxDecoration(
                color: _NcDetailColors.red.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: _NcDetailColors.red.withValues(alpha: .25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 12, color: _NcDetailColors.red),
                  const SizedBox(width: 6),
                  Expanded(child: Text(motivo, style: const TextStyle(color: _NcDetailColors.red, fontSize: 11, height: 1.4))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExecucaoAtividadeCard extends StatelessWidget {
  final int index;
  final String raw;
  final String? token;
  const _ExecucaoAtividadeCard({required this.index, required this.raw, this.token});

  @override
  Widget build(BuildContext context) {
    // Split §§ for per-activity evidence IDs
    final parts = raw.split(' §§ ');
    final mainPart = parts[0];
    final evidenceIds = parts.length > 1
        ? parts[1].split(',').where((e) => e.isNotEmpty).toList()
        : <String>[];

    // Parse status suffix
    final sepIdx = mainPart.lastIndexOf(' || ');
    final content = sepIdx >= 0 ? mainPart.substring(0, sepIdx) : mainPart;
    final statusPart = sepIdx >= 0 ? mainPart.substring(sepIdx + 4) : '';
    final isRejeitada = statusPart.startsWith('REJEITADA');
    final isAprovada = statusPart == 'APROVADA';
    final isPendente = !isAprovada && !isRejeitada;
    String? motivo;
    if (isRejeitada && statusPart.contains(': ')) {
      motivo = statusPart.substring(statusPart.indexOf(': ') + 2).trim();
    }

    // Parse titulo — desc
    final dashIdx = content.indexOf(' — ');
    final titulo = dashIdx >= 0 ? content.substring(0, dashIdx) : content;
    final descricao = dashIdx >= 0 ? content.substring(dashIdx + 3) : null;

    final color = isRejeitada ? _NcDetailColors.red : isAprovada ? _NcDetailColors.green : const Color(0xFF7C3AED);
    final bgColor = isRejeitada ? const Color(0xFF2A1A1A) : isAprovada ? const Color(0xFF0D2318) : const Color(0xFF1E1535);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20, height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(6)),
                child: Text('${index + 1}', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
                    if (descricao != null && descricao.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(descricao, style: const TextStyle(color: _NcDetailColors.muted, fontSize: 11, height: 1.35)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: color.withValues(alpha: .4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isRejeitada ? Icons.cancel_outlined : isPendente ? Icons.hourglass_empty_rounded : Icons.check_circle_outline_rounded, size: 10, color: color),
                    const SizedBox(width: 3),
                    Text(isRejeitada ? 'Reprovada' : isPendente ? 'Pendente' : 'Aprovada', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
          if (motivo != null && motivo.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
              decoration: BoxDecoration(
                color: _NcDetailColors.red.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: _NcDetailColors.red.withValues(alpha: .25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 12, color: _NcDetailColors.red),
                  const SizedBox(width: 6),
                  Expanded(child: Text(motivo, style: const TextStyle(color: _NcDetailColors.red, fontSize: 11, height: 1.4))),
                ],
              ),
            ),
          ],
          if (evidenceIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: evidenceIds.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (ctx, ei) {
                  final url = '${AppConfig.apiBaseUrl}/api/evidencias/${evidenceIds[ei]}/download';
                  return GestureDetector(
                    onTap: () => _openViewer(ctx, url, 'evidencia_${ei + 1}.jpg'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: token != null
                          ? Image(
                              image: NetworkImage(url, headers: {'Authorization': 'Bearer $token'}),
                              width: 72, height: 72, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(width: 72, height: 72, color: _NcDetailColors.surface2, child: const Icon(Icons.broken_image_rounded, color: _NcDetailColors.muted, size: 16)),
                            )
                          : Container(width: 72, height: 72, color: _NcDetailColors.surface2, child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5))),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openViewer(BuildContext context, String url, String filename) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _ImageViewerDialog(url: url, token: token, filename: filename),
    );
  }
}

class _AtividadesSection extends StatelessWidget {
  final List<Map<String, dynamic>> atividades;
  const _AtividadesSection({required this.atividades});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ATIVIDADES', style: TextStyle(color: Color(0xFFD7E8FF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4)),
        const SizedBox(height: 10),
        for (var i = 0; i < atividades.length; i++)
          _AtividadeCard(index: i, atividade: atividades[i]),
      ],
    );
  }
}

class _AtividadeCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> atividade;
  const _AtividadeCard({required this.index, required this.atividade});

  @override
  Widget build(BuildContext context) {
    final titulo = atividade['titulo'] as String? ?? atividade['descricao'] as String? ?? 'Atividade ${index + 1}';
    final responsavel = atividade['responsavelNome'] as String? ?? atividade['responsavel'] as String? ?? '—';
    final prazo = _fmtDate(atividade['prazo'] as String? ?? atividade['dataLimite'] as String?);
    final concluida = atividade['concluida'] == true || atividade['status'] == 'CONCLUIDA';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: concluida ? const Color(0xFF15281F) : _NcDetailColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _NcDetailColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22, height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: concluida ? _NcDetailColors.green : _NcDetailColors.surface2,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: concluida ? _NcDetailColors.green : _NcDetailColors.borderStrong),
              ),
              child: concluida
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                  : Text('${index + 1}', style: const TextStyle(color: _NcDetailColors.text, fontSize: 11, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: TextStyle(color: _NcDetailColors.text, fontSize: 13, fontWeight: FontWeight.w800, height: 1.35, decoration: concluida ? TextDecoration.lineThrough : null)),
                  const SizedBox(height: 4),
                  Text('$responsavel · até $prazo', style: const TextStyle(color: _NcDetailColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExecucaoTab extends ConsumerWidget {
  final NcDetail nc;
  const _ExecucaoTab({required this.nc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshots = nc.execucaoSnapshots;
    final tokenAsync = ref.watch(_jwtTokenProvider);

    if (snapshots.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          _DarkCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: const [
                  Icon(Icons.engineering_outlined, color: _NcDetailColors.muted, size: 32),
                  SizedBox(height: 8),
                  Text('Nenhuma execução submetida ainda.', style: TextStyle(color: _NcDetailColors.muted, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        for (var i = 0; i < snapshots.length; i++) ...[
          _ExecucaoSnapshotCard(index: i, snapshot: snapshots[i], token: tokenAsync.valueOrNull, ncAtividades: nc.atividades),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ExecucaoSnapshotCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> snapshot;
  final String? token;
  final List<Map<String, dynamic>> ncAtividades;
  const _ExecucaoSnapshotCard({required this.index, required this.snapshot, this.token, this.ncAtividades = const []});

  @override
  State<_ExecucaoSnapshotCard> createState() => _ExecucaoSnapshotCardState();
}

class _ExecucaoSnapshotCardState extends State<_ExecucaoSnapshotCard> {
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _expanded = widget.index == widget.index; // sempre expandido por padrão
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.snapshot;
    final status = (s['status'] as String? ?? '').toUpperCase();
    final isAprovado = status == 'APROVADO';
    final isReprovado = status == 'REPROVADO';
    final comentario = s['comentarioRevisao'] as String?;
    final dataSubmissao = _fmtDateTime(s['dataSubmissao'] as String?);
    final descricao = s['descricaoExecucao'] as String?;
    final atividades = (s['atividades'] as List<dynamic>? ?? []).cast<String>();
    final evidencias = (s['evidencias'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    final statusColor = isAprovado ? _NcDetailColors.green : isReprovado ? _NcDetailColors.red : const Color(0xFF7C3AED);
    final statusLabel = isAprovado ? 'APROVADO' : isReprovado ? 'REPROVADO' : 'PENDENTE';

    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Text('Execução ${widget.index + 1}', style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: .15), borderRadius: BorderRadius.circular(99), border: Border.all(color: statusColor.withValues(alpha: .4))),
                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900)),
                ),
                const Spacer(),
                Text(dataSubmissao, style: const TextStyle(color: _NcDetailColors.muted, fontSize: 11)),
                const SizedBox(width: 6),
                Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: _NcDetailColors.muted, size: 18),
              ],
            ),
          ),
          // Comentário de revisão sempre visível
          if (comentario != null && comentario.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isReprovado ? _NcDetailColors.red : _NcDetailColors.green).withValues(alpha: .08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: (isReprovado ? _NcDetailColors.red : _NcDetailColors.green).withValues(alpha: .35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(isReprovado ? Icons.cancel_outlined : Icons.check_circle_outline_rounded, size: 14, color: isReprovado ? _NcDetailColors.red : _NcDetailColors.green),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isReprovado ? 'Motivo da reprovação' : 'Comentário de aprovação', style: TextStyle(color: isReprovado ? _NcDetailColors.red : _NcDetailColors.green, fontSize: 10, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 3),
                        Text(comentario, style: const TextStyle(color: _NcDetailColors.text, fontSize: 12, height: 1.45)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_expanded) ...[
            const SizedBox(height: 14),
            const Divider(color: _NcDetailColors.border, height: 1),
            const SizedBox(height: 14),

            // ── Para PENDENTE: mescla atividades já aprovadas + submetidas ──
            if (!isAprovado && !isReprovado) ...[
              ..._buildPendenteAtividades(atividades, evidencias),
            ] else ...[
              // ── APROVADO/REPROVADO: cards com status por atividade ──
              if (atividades.isNotEmpty) ...[
                const Text('ATIVIDADES', style: TextStyle(color: Color(0xFFD7E8FF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4)),
                const SizedBox(height: 8),
                for (var i = 0; i < atividades.length; i++) ...[
                  _ExecucaoAtividadeCard(index: i, raw: atividades[i], token: widget.token),
                  if (i < atividades.length - 1) const SizedBox(height: 8),
                ],
                const SizedBox(height: 12),
              ],
            ],

            // Descrição geral
            if (descricao != null && descricao.isNotEmpty) ...[
              const Text('DESCRIÇÃO DA EXECUÇÃO', style: TextStyle(color: Color(0xFFD7E8FF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4)),
              const SizedBox(height: 6),
              Text(descricao, style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, height: 1.5)),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }

  List<Widget> _buildPendenteAtividades(List<String> snapshotAtivs, List<Map<String, dynamic>> evidencias) {
    // Títulos submetidos neste round
    final submittedTitles = snapshotAtivs.map((raw) {
      final dashIdx = raw.indexOf(' — ');
      return (dashIdx >= 0 ? raw.substring(0, dashIdx) : raw).trim();
    }).toSet();

    // Atividades previamente aprovadas (de rounds anteriores) que não estão neste snapshot
    final prevAprovadas = widget.ncAtividades
        .where((a) => (a['statusExecucao'] as String? ?? '').toUpperCase() == 'APROVADA')
        .where((a) => !submittedTitles.contains((a['titulo'] as String? ?? '').trim()))
        .toList();

    // Evidências por atividade (para atividades submetidas)
    final evsByAtivTitle = <String, List<Map<String, dynamic>>>{};
    for (final a in widget.ncAtividades) {
      final titulo = (a['titulo'] as String? ?? '').trim();
      if (submittedTitles.contains(titulo)) {
        final evs = (a['evidencias'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        if (evs.isNotEmpty) evsByAtivTitle[titulo] = evs;
      }
    }

    final widgets = <Widget>[];

    // Seção: já aprovadas
    if (prevAprovadas.isNotEmpty) {
      widgets.add(const Text('JÁ APROVADAS EM ROUND ANTERIOR', style: TextStyle(color: _NcDetailColors.green, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .4)));
      widgets.add(const SizedBox(height: 6));
      for (var i = 0; i < prevAprovadas.length; i++) {
        final a = prevAprovadas[i];
        widgets.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFF0D2318), borderRadius: BorderRadius.circular(10), border: Border.all(color: _NcDetailColors.green.withValues(alpha: .35))),
          child: Row(children: [
            const Icon(Icons.check_circle_outline_rounded, size: 14, color: _NcDetailColors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(a['titulo'] as String? ?? '', style: const TextStyle(color: _NcDetailColors.green, fontSize: 12, fontWeight: FontWeight.w700))),
          ]),
        ));
        if (i < prevAprovadas.length - 1) widgets.add(const SizedBox(height: 6));
      }
      widgets.add(const SizedBox(height: 14));
    }

    // Seção: submetidas neste round (pendentes de revisão)
    if (snapshotAtivs.isNotEmpty) {
      widgets.add(const Text('SUBMETIDAS PARA REVISÃO', style: TextStyle(color: Color(0xFFD7E8FF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .4)));
      widgets.add(const SizedBox(height: 6));
      for (var i = 0; i < snapshotAtivs.length; i++) {
        final raw = snapshotAtivs[i];
        final dashIdx = raw.indexOf(' — ');
        final titulo = dashIdx >= 0 ? raw.substring(0, dashIdx) : raw;
        final descricaoExec = dashIdx >= 0 ? raw.substring(dashIdx + 3) : '';
        final atividadeEvs = evsByAtivTitle[titulo.trim()] ?? [];

        widgets.add(Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1535),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: .4)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 20, height: 20, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: .2), borderRadius: BorderRadius.circular(6)), child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 10, fontWeight: FontWeight.w900))),
              const SizedBox(width: 8),
              Expanded(child: Text(titulo, style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, fontWeight: FontWeight.w700, height: 1.3))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: .15), borderRadius: BorderRadius.circular(99), border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: .4))),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.hourglass_empty_rounded, size: 10, color: Color(0xFF7C3AED)), SizedBox(width: 3), Text('Pendente', style: TextStyle(color: Color(0xFF7C3AED), fontSize: 9, fontWeight: FontWeight.w900))]),
              ),
            ]),
            if (descricaoExec.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _NcDetailColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _NcDetailColors.border)),
                child: Text(descricaoExec, style: const TextStyle(color: _NcDetailColors.muted, fontSize: 11, height: 1.4)),
              ),
            ],
            if (atividadeEvs.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: atividadeEvs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, ei) {
                    final url = '${AppConfig.apiBaseUrl}/api/evidencias/${atividadeEvs[ei]['id']}/download';
                    return GestureDetector(
                      onTap: () => _openViewer(ctx, url, atividadeEvs[ei]['nomeArquivo'] as String? ?? 'foto.jpg'),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.token != null
                            ? Image(image: NetworkImage(url, headers: {'Authorization': 'Bearer ${widget.token}'}), width: 72, height: 72, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 72, height: 72, color: _NcDetailColors.surface, child: const Icon(Icons.broken_image_rounded, color: _NcDetailColors.muted, size: 16)))
                            : Container(width: 72, height: 72, color: _NcDetailColors.surface),
                      ),
                    );
                  },
                ),
              ),
            ],
          ]),
        ));
        if (i < snapshotAtivs.length - 1) widgets.add(const SizedBox(height: 8));
      }
      widgets.add(const SizedBox(height: 12));
    }

    // Fotos gerais do snapshot (fallback se evidencias por atividade não encontradas)
    if (evidencias.isNotEmpty) {
      final snapshotEvIds = <String>{};
      for (final evs in evsByAtivTitle.values) {
        for (final ev in evs) { snapshotEvIds.add(ev['id'] as String? ?? ''); }
      }
      final extraEvs = evidencias.where((ev) => !snapshotEvIds.contains(ev['id'] as String? ?? '')).toList();
      if (extraEvs.isNotEmpty) {
        widgets.add(const Text('OUTRAS FOTOS', style: TextStyle(color: Color(0xFFD7E8FF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .4)));
        widgets.add(const SizedBox(height: 6));
        widgets.add(SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: extraEvs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, ei) {
              final url = '${AppConfig.apiBaseUrl}/api/evidencias/${extraEvs[ei]['id']}/download';
              return GestureDetector(
                onTap: () => _openViewer(ctx, url, extraEvs[ei]['nomeArquivo'] as String? ?? 'foto.jpg'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: widget.token != null
                      ? Image(image: NetworkImage(url, headers: {'Authorization': 'Bearer ${widget.token}'}), width: 90, height: 90, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 90, height: 90, color: _NcDetailColors.surface2, child: const Icon(Icons.broken_image_rounded, color: _NcDetailColors.muted)))
                      : Container(width: 90, height: 90, color: _NcDetailColors.surface2),
                ),
              );
            },
          ),
        ));
      }
    } else {
      widgets.add(const Row(children: [Icon(Icons.photo_library_outlined, size: 14, color: _NcDetailColors.muted2), SizedBox(width: 6), Text('Nenhuma foto anexada.', style: TextStyle(color: _NcDetailColors.muted2, fontSize: 12))]));
    }

    return widgets;
  }

  void _openViewer(BuildContext context, String url, String filename) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _ImageViewerDialog(url: url, token: widget.token, filename: filename),
    );
  }
}

class _HistoricoTab extends StatelessWidget {
  final NcDetail nc;
  const _HistoricoTab({required this.nc});

  static String _statusLabel(String? s) => switch (s?.toUpperCase()) {
    'ABERTA'                    => 'Aberta',
    'AGUARDANDO_TRATATIVA'      => 'Aguard. Tratativa',
    'AGUARDANDO_APROVACAO_PLANO'=> 'Aguard. Aprovação',
    'EM_EXECUCAO'               => 'Em Execução',
    'AGUARDANDO_VALIDACAO_FINAL'=> 'Aguard. Validação',
    'EM_AJUSTE_PELO_EXTERNO'    => 'Reprovado',
    'CONCLUIDO'                 => 'Concluído',
    _                           => s ?? '—',
  };

  static String _acaoLabel(String? acao) => switch (acao?.toUpperCase()) {
    'CRIACAO'          => 'NC registrada',
    'ENVIO_PLANO'      => 'Plano de ação enviado',
    'APROVACAO'        => 'NC aprovada',
    'REJEICAO'         => 'NC rejeitada',
    'CONCLUSAO'        => 'NC concluída',
    'COMENTARIO'       => 'Comentário adicionado',
    'EDICAO'           => 'NC editada',
    _                  => acao ?? 'Ação',
  };

  static Color _acaoColor(String? acao) => switch (acao?.toUpperCase()) {
    'CRIACAO'     => _NcDetailColors.blue,
    'APROVACAO'   => _NcDetailColors.green,
    'CONCLUSAO'   => _NcDetailColors.green,
    'REJEICAO'    => _NcDetailColors.red,
    _             => _NcDetailColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    final items = nc.historico;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: [
        _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Linha do Tempo'),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('Sem histórico disponível.', style: TextStyle(color: _NcDetailColors.muted, fontSize: 13))),
                )
              else
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(color: _acaoColor(items[i]['acao'] as String?), shape: BoxShape.circle),
                            ),
                            if (i < items.length - 1)
                              Container(width: 1, height: 40, color: _NcDetailColors.border),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                items[i]['usuarioNome'] as String? ?? '—',
                                style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                _acaoLabel(items[i]['acao'] as String?),
                                style: const TextStyle(color: _NcDetailColors.muted, fontSize: 12, height: 1.35),
                              ),
                              if (items[i]['comentario'] != null)
                                Text('"${items[i]['comentario']}"',
                                    style: const TextStyle(color: _NcDetailColors.muted, fontSize: 11, fontStyle: FontStyle.italic)),
                              Text(
                                _fmtDateTime(items[i]['dataAcao'] as String?),
                                style: const TextStyle(color: _NcDetailColors.muted2, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
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

class _DetailActions extends ConsumerWidget {
  final NcDetail nc;
  final LoginResponse? user;
  const _DetailActions({required this.nc, this.user});

  bool get _isEng => user?.perfil == 'ENGENHEIRO' || (user?.isAdmin ?? false);
  bool get _canAct => user != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (user == null) return const SizedBox.shrink();

    final status = nc.status.toUpperCase();
    final perfil = user!.perfil.toUpperCase();
    final isAberta = status == 'ABERTA';
    final isAjuste = status == 'EM_AJUSTE_PELO_EXTERNO';
    final canAprovarPlano = status == 'AGUARDANDO_APROVACAO_PLANO' && _isEng;
    // Só o responsável pela tratativa (responsavelTratativa) pode submeter execução
    final isResponsavelTratativa = user != null && user!.email == nc.responsavelTrativaEmail;
    final canPreencherPlano = (status == 'AGUARDANDO_TRATATIVA' || status == 'EM_AJUSTE_PELO_EXTERNO') && isResponsavelTratativa;
    final isAguardandoTratativa = status == 'AGUARDANDO_TRATATIVA';
    final canExecutar = status == 'EM_EXECUCAO' && isResponsavelTratativa;
    final canAprovarEvidencias = status == 'AGUARDANDO_VALIDACAO_FINAL' && _isEng;
    final isDone = status == 'CONCLUIDO' || status == 'FECHADO' || status == 'CONCLUIDA' || status == 'FECHADA';

    if (isDone && !isAberta && !isAjuste && !canAprovarPlano && !canExecutar && !canAprovarEvidencias) {
      return const SizedBox.shrink();
    }
    if (isDone) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(color: _NcDetailColors.surface, border: Border(top: BorderSide(color: _NcDetailColors.border))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AGUARDANDO_TRATATIVA: responsável preenche, outros veem banner
          if (canPreencherPlano) ...[
            _ActionBtn(
              label: 'Preencher Plano de Ação',
              icon: Icons.assignment_outlined,
              color: _NcDetailColors.blue,
              onTap: () => _showInvestigacao(context, ref),
            ),
            const SizedBox(height: 8),
          ] else if (isAguardandoTratativa) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2030),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A3A55)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded, size: 18, color: _NcDetailColors.yellow),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Aguardando ${nc.responsavelTrativaNome ?? 'o responsável'} preencher o plano de ação.',
                      style: const TextStyle(color: _NcDetailColors.muted, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          // ABERTA: botão visível para todos, mas só o criador pode usar
          if (isAberta)
            _ActionBtn(
              label: 'Enviar para Plano de Ação',
              icon: Icons.send_rounded,
              color: _NcDetailColors.blue,
              onTap: () => _onEnviarPlano(context, ref),
            ),
          if (isAjuste && !canPreencherPlano) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _NcDetailColors.red.withValues(alpha: .4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions_rounded, size: 18, color: _NcDetailColors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Aguardando ajuste do responsável pela tratativa.',
                      style: const TextStyle(color: _NcDetailColors.muted, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (canAprovarPlano) ...[
            _ActionBtn(
              label: 'Revisar Atividades',
              icon: Icons.fact_check_outlined,
              color: _NcDetailColors.blue,
              onTap: () => _showRevisarAtividades(context, ref),
            ),
          ],
          if (status == 'EM_EXECUCAO') ...[
            if (canExecutar)
              _ActionBtn(
                label: 'Submeter Execução',
                icon: Icons.play_circle_outline_rounded,
                color: _NcDetailColors.blue,
                onTap: () => _showExecucao(context, ref),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2030),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A3A55)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded, size: 18, color: _NcDetailColors.yellow),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Aguarde o responsável pela tratativa evidenciar a execução.',
                        style: const TextStyle(color: _NcDetailColors.muted, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (canAprovarEvidencias) ...[
            _ActionBtn(
              label: 'Revisar Execução',
              icon: Icons.verified_outlined,
              color: _NcDetailColors.green,
              onTap: () => _showRevisarExecucao(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  bool get _isCriador =>
      user != null && (user!.id == nc.usuarioCriacaoId || user!.email == nc.usuarioCriacaoEmail);

  Future<void> _onEnviarPlano(BuildContext context, WidgetRef ref) async {
    if (!_isCriador) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF151A21),
          title: const Text('Sem permissão', style: TextStyle(color: _NcDetailColors.text)),
          content: Text(
            'Apenas quem registrou esta NC pode enviá-la para plano de ação.\n\nRegistrado por: ${nc.usuarioCriacaoNome}',
            style: const TextStyle(color: _NcDetailColors.muted, fontSize: 13, height: 1.5),
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
          ],
        ),
      );
      return;
    }

    // Confirmação com dados principais
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF151A21),
        title: const Row(
          children: [
            Icon(Icons.send_rounded, color: _NcDetailColors.blue, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Enviar para Plano de Ação', style: TextStyle(color: _NcDetailColors.text, fontSize: 16, fontWeight: FontWeight.w900))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirme os dados antes de prosseguir:', style: TextStyle(color: _NcDetailColors.muted, fontSize: 12)),
            const SizedBox(height: 12),
            _ConfirmRow(label: 'NC', value: nc.titulo),
            _ConfirmRow(label: 'Estabelecimento', value: nc.estabelecimentoNome),
            if (nc.dataLimiteResolucao != null)
              _ConfirmRow(label: 'Data Limite', value: _fmtDate(nc.dataLimiteResolucao), valueColor: nc.vencida ? _NcDetailColors.red : null),
            if (nc.responsavelNcNome != null)
              _ConfirmRow(label: 'Resp. Tratativa', value: nc.responsavelNcNome!),
            if (nc.responsavelTrativaNome != null)
              _ConfirmRow(label: 'Resp. NC', value: nc.responsavelTrativaNome!),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF4A390A), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFD29922).withValues(alpha: .4))),
              child: const Text('Após confirmar, não será mais possível editar os dados da NC. O responsável pela tratativa será notificado para preencher o plano de investigação.', style: TextStyle(color: Color(0xFFD29922), fontSize: 11, height: 1.5)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: _NcDetailColors.muted))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _NcDetailColors.blue),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar e Preencher', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;
    final dio = ref.read(dioProvider);
    try {
      await ativarNc(dio, nc.id);
      ref.invalidate(_ncDetailProvider(nc.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NC enviada para plano de ação. O responsável será notificado.')),
        );
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _showInvestigacao(BuildContext context, WidgetRef ref) async {
    final dio = ref.read(dioProvider);
    final isAjuste = nc.status.toUpperCase() == 'EM_AJUSTE_PELO_EXTERNO';
    final rejeitadas = isAjuste
        ? nc.atividades.where((a) => (a['status'] as String? ?? '').toUpperCase() == 'REJEITADA').toList()
        : <Map<String, dynamic>>[];
    final aprovadas = isAjuste
        ? nc.atividades.where((a) => (a['status'] as String? ?? '').toUpperCase() == 'APROVADA').toList()
        : <Map<String, dynamic>>[];
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151A21),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _InvestigacaoSheet(
        ncId: nc.id,
        dio: dio,
        isAjuste: isAjuste,
        initialPorques: isAjuste ? nc.porques : const [],
        initialCausaRaiz: isAjuste ? nc.causaRaiz : null,
        initialAtividades: rejeitadas,
        atividadesAprovadas: aprovadas,
      ),
    );
    ref.invalidate(_ncDetailProvider(nc.id));
  }

  Future<void> _showExecucao(BuildContext context, WidgetRef ref) async {
    final dio = ref.read(dioProvider);
    // Após aprovação do plano as atividades ficam com status APROVADA.
    final pendentes = nc.atividades
        .where((a) => (a['status'] as String? ?? '').toUpperCase() == 'APROVADA')
        .toList();

    final token = ref.read(_jwtTokenProvider).valueOrNull;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151A21),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ExecucaoSheet(ncId: nc.id, atividades: pendentes, dio: dio, token: token),
    );
    ref.invalidate(_ncDetailProvider(nc.id));
  }

  Future<void> _showRejeitar(BuildContext context, WidgetRef ref, String tipo) async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151A21),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(color: _NcDetailColors.muted2, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _NcDetailColors.red.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.cancel_outlined, color: _NcDetailColors.red, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Rejeitar ${tipo == 'plano' ? 'Plano de Ação' : 'Evidências'}',
                        style: const TextStyle(color: _NcDetailColors.text, fontSize: 17, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Descreva o motivo da rejeição. O responsável será notificado.',
                    style: const TextStyle(color: _NcDetailColors.muted, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  const Text('MOTIVO', style: TextStyle(color: Color(0xFFD7E8FF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: ctrl,
                    maxLines: 6,
                    minLines: 4,
                    autofocus: true,
                    style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, height: 1.55),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o motivo da rejeição' : null,
                    decoration: InputDecoration(
                      hintText: 'Ex.: O plano de ação não contempla todas as causas identificadas na análise de risco...',
                      hintStyle: const TextStyle(color: _NcDetailColors.muted, fontSize: 12, height: 1.55),
                      filled: true,
                      fillColor: _NcDetailColors.surface2,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _NcDetailColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _NcDetailColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _NcDetailColors.red.withValues(alpha: .6), width: 1.5)),
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _NcDetailColors.red)),
                      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _NcDetailColors.red, width: 1.5)),
                      errorStyle: const TextStyle(color: _NcDetailColors.red, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _NcDetailColors.muted,
                            side: const BorderSide(color: _NcDetailColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _NcDetailColors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: loading ? null : () {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(ctx, true);
                            }
                          },
                          icon: loading
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.cancel_outlined, size: 16),
                          label: Text(
                            'Confirmar Rejeição',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (ok != true || ctrl.text.trim().isEmpty) return;
    if (!context.mounted) return;
    final dio = ref.read(dioProvider);
    try {
      if (tipo == 'plano') await rejeitarPlano(dio, nc.id, ctrl.text.trim());
      else await rejeitarEvidencias(dio, nc.id, ctrl.text.trim());
      ref.invalidate(_ncDetailProvider(nc.id));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _confirmarAprovar(BuildContext context, WidgetRef ref, String tipo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF151A21),
        title: Text('Aprovar ${tipo == 'plano' ? 'Plano' : 'Evidências'}', style: const TextStyle(color: _NcDetailColors.text)),
        content: Text('Confirmar aprovação?', style: const TextStyle(color: _NcDetailColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: _NcDetailColors.muted))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _NcDetailColors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aprovar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    final dio = ref.read(dioProvider);
    try {
      if (tipo == 'plano') await aprovarPlano(dio, nc.id);
      else await aprovarEvidencias(dio, nc.id);
      ref.invalidate(_ncDetailProvider(nc.id));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _showRevisarAtividades(BuildContext context, WidgetRef ref) async {
    final dio = ref.read(dioProvider);
    final toReview = nc.atividades
        .where((a) => ['PENDENTE', 'APROVADA'].contains((a['status'] as String? ?? '').toUpperCase()))
        .toList();
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151A21),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RevisarAtividadesSheet(ncId: nc.id, atividades: toReview, porques: nc.porques, causaRaiz: nc.causaRaiz, dio: dio),
    );
    ref.invalidate(_ncDetailProvider(nc.id));
  }

  Future<void> _showRevisarExecucao(BuildContext context, WidgetRef ref) async {
    final dio = ref.read(dioProvider);
    final token = ref.read(_jwtTokenProvider).valueOrNull;

    // Constrói mapa titulo→evidências a partir de todos os snapshots (§§ evId1,evId2,...)
    final evidenciasPorTitulo = <String, List<Map<String, dynamic>>>{};
    for (final snap in nc.execucaoSnapshots) {
      final snapshotAtivs = (snap['atividades'] as List<dynamic>? ?? []).cast<String>();
      final snapshotEvs = (snap['evidencias'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      final evById = <String, Map<String, dynamic>>{
        for (final ev in snapshotEvs) (ev['id'] as String? ?? ''): ev,
      };
      for (final raw in snapshotAtivs) {
        final ssIdx = raw.indexOf(' §§ ');
        if (ssIdx < 0) continue;
        final beforeSs = raw.substring(0, ssIdx);
        final dashIdx = beforeSs.indexOf(' — ');
        final titulo = (dashIdx >= 0 ? beforeSs.substring(0, dashIdx) : beforeSs).trim();
        final evIds = raw.substring(ssIdx + 4).split(',').where((s) => s.isNotEmpty);
        if (titulo.isEmpty) continue;
        evidenciasPorTitulo[titulo] = evIds.map((id) => evById[id]).whereType<Map<String, dynamic>>().toList();
      }
    }

    // Enriquece mapa da atividade com evidências do snapshot se o campo estiver vazio
    Map<String, dynamic> enrich(Map<String, dynamic> a) {
      final existing = (a['evidencias'] as List<dynamic>? ?? []);
      if (existing.isNotEmpty) return a;
      final titulo = (a['titulo'] as String? ?? '').trim();
      final fromSnap = evidenciasPorTitulo[titulo] ?? [];
      if (fromSnap.isEmpty) return a;
      return Map<String, dynamic>.from(a)..['evidencias'] = fromSnap;
    }

    final pendentes = nc.atividades
        .where((a) => (a['statusExecucao'] as String? ?? '').toUpperCase() == 'PENDENTE')
        .map(enrich)
        .toList();
    final jaAprovadas = nc.atividades
        .where((a) => (a['statusExecucao'] as String? ?? '').toUpperCase() == 'APROVADA')
        .map(enrich)
        .toList();

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151A21),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RevisarExecucaoSheet(ncId: nc.id, atividades: pendentes, atividadesJaAprovadas: jaAprovadas, porques: nc.porques, dio: dio, token: token),
    );
    ref.invalidate(_ncDetailProvider(nc.id));
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool filled;
  const _ActionBtn({required this.label, required this.icon, required this.color, required this.onTap, this.filled = true});

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: onTap,
          icon: Icon(icon, size: 16),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color.withValues(alpha: .5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}


// ── Revisar Atividades Sheet ──────────────────────────────────────────────────
class _RevisarAtividadesSheet extends StatefulWidget {
  final String ncId;
  final List<Map<String, dynamic>> atividades;
  final List<Map<String, dynamic>> porques;
  final String? causaRaiz;
  final dio_pkg.Dio dio;
  const _RevisarAtividadesSheet({required this.ncId, required this.atividades, required this.porques, this.causaRaiz, required this.dio});

  @override
  State<_RevisarAtividadesSheet> createState() => _RevisarAtividadesSheetState();
}

class _RevisarAtividadesSheetState extends State<_RevisarAtividadesSheet> {
  late final List<String> _decisoes;
  late final List<TextEditingController> _motivoCtrl;
  String? _porqueDecisao;
  final _comentarioCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _decisoes = widget.atividades.map((a) {
      final s = (a['status'] as String? ?? '').toUpperCase();
      return s == 'REJEITADA' ? 'REJEITADA' : 'APROVADA';
    }).toList();
    _motivoCtrl = List.generate(widget.atividades.length, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _motivoCtrl) c.dispose();
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    for (var i = 0; i < widget.atividades.length; i++) {
      if (_decisoes[i] == 'REJEITADA' && _motivoCtrl[i].text.trim().isEmpty) {
        setState(() => _error = 'Informe o motivo para cada atividade reprovada.');
        return;
      }
    }
    final temReprovacao = _decisoes.any((d) => d == 'REJEITADA') || _porqueDecisao == 'REJEITADA';
    if (temReprovacao && _comentarioCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Informe o motivo geral da reprovação.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final decisoes = <Map<String, dynamic>>[];
      for (var i = 0; i < widget.atividades.length; i++) {
        final statusAtual = (widget.atividades[i]['status'] as String? ?? '').toUpperCase();
        if (statusAtual != _decisoes[i] || statusAtual == 'PENDENTE') {
          decisoes.add({
            'atividadeId': widget.atividades[i]['id'] as String,
            'status': _decisoes[i],
            if (_decisoes[i] == 'REJEITADA') 'motivo': _motivoCtrl[i].text.trim(),
          });
        }
      }
      final porqueRejeitado = _porqueDecisao == 'REJEITADA';
      final comentario = _comentarioCtrl.text.trim().isEmpty ? null : _comentarioCtrl.text.trim();
      await revisarAtividades(
        widget.dio, widget.ncId, decisoes,
        comentario: comentario,
        porqueRejeitado: porqueRejeitado,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: _NcDetailColors.muted2, borderRadius: BorderRadius.circular(99))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _NcDetailColors.blue.withValues(alpha: .15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.fact_check_outlined, color: _NcDetailColors.blue, size: 18)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Revisar Atividades', style: TextStyle(color: _NcDetailColors.text, fontSize: 17, fontWeight: FontWeight.w900)),
                      Text('Aprove ou reprove cada atividade do plano', style: TextStyle(color: _NcDetailColors.muted, fontSize: 12, height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: _NcDetailColors.border, height: 1),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              children: [
                if (widget.porques.isNotEmpty) ...[
                  const Text('5 PORQUÊS', style: TextStyle(color: Color(0xFFD7E8FF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _porqueDecisao == 'APROVADA'
                          ? const Color(0xFF16a34a).withValues(alpha: .08)
                          : _porqueDecisao == 'REJEITADA'
                              ? _NcDetailColors.red.withValues(alpha: .08)
                              : _NcDetailColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _porqueDecisao == 'APROVADA'
                            ? const Color(0xFF16a34a).withValues(alpha: .5)
                            : _porqueDecisao == 'REJEITADA'
                                ? _NcDetailColors.red.withValues(alpha: .5)
                                : _NcDetailColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                          child: Row(
                            children: [
                              Expanded(child: _ToggleBtn(label: 'Aprovar', icon: Icons.check_circle_outline_rounded, active: _porqueDecisao == 'APROVADA', color: _NcDetailColors.green, onTap: () => setState(() => _porqueDecisao = 'APROVADA'))),
                              const SizedBox(width: 8),
                              Expanded(child: _ToggleBtn(label: 'Reprovar', icon: Icons.cancel_outlined, active: _porqueDecisao == 'REJEITADA', color: _NcDetailColors.red, onTap: () => setState(() => _porqueDecisao = 'REJEITADA'))),
                            ],
                          ),
                        ),
                        const Divider(color: _NcDetailColors.border, height: 1),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < widget.porques.length; i++) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 22, height: 22,
                                      decoration: BoxDecoration(color: const Color(0xFF1e40af).withValues(alpha: .2), shape: BoxShape.circle),
                                      alignment: Alignment.center,
                                      child: Text('${i + 1}', style: const TextStyle(color: _NcDetailColors.blue, fontSize: 11, fontWeight: FontWeight.w900)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(widget.porques[i]['pergunta'] as String? ?? '', style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, fontWeight: FontWeight.w600)),
                                          if ((widget.porques[i]['resposta'] as String? ?? '').isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Row(
                                                children: [
                                                  Container(width: 2, height: 30, decoration: BoxDecoration(color: _NcDetailColors.blue.withValues(alpha: .4), borderRadius: BorderRadius.circular(1))),
                                                  const SizedBox(width: 6),
                                                  Expanded(child: Text(widget.porques[i]['resposta'] as String, style: const TextStyle(color: _NcDetailColors.muted, fontSize: 12, height: 1.4))),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (i < widget.porques.length - 1) const SizedBox(height: 10),
                              ],
                              if (widget.causaRaiz != null && widget.causaRaiz!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                const Divider(color: _NcDetailColors.border, height: 1),
                                const SizedBox(height: 10),
                                const Text('CAUSA RAIZ IDENTIFICADA', style: TextStyle(color: Color(0xFFD7E8FF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .4)),
                                const SizedBox(height: 4),
                                Text(widget.causaRaiz!, style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, height: 1.4)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: _NcDetailColors.border, height: 1),
                  const SizedBox(height: 12),
                ],
                const Text('ATIVIDADES', style: TextStyle(color: Color(0xFFD7E8FF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4)),
                const SizedBox(height: 8),
                if (widget.atividades.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Text('Nenhuma atividade pendente.', style: TextStyle(color: _NcDetailColors.muted, fontSize: 13))))
                else
                  for (var i = 0; i < widget.atividades.length; i++) ...[
                    _AtividadeRevisaoCard(index: i, atividade: widget.atividades[i], decisao: _decisoes[i], motivoCtrl: _motivoCtrl[i], onDecisao: (d) => setState(() => _decisoes[i] = d)),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  final temReprovacao = _decisoes.any((d) => d == 'REJEITADA') || _porqueDecisao == 'REJEITADA';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        temReprovacao ? 'MOTIVO GERAL DA REPROVAÇÃO *' : 'COMENTÁRIO GERAL (opcional)',
                        style: TextStyle(color: temReprovacao ? _NcDetailColors.red : const Color(0xFFD7E8FF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _comentarioCtrl,
                        maxLines: 3,
                        minLines: 2,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, height: 1.55),
                        decoration: InputDecoration(
                          hintText: temReprovacao ? 'Descreva o motivo da reprovação...' : 'Observações gerais sobre a revisão...',
                          hintStyle: const TextStyle(color: _NcDetailColors.muted, fontSize: 12),
                          filled: true, fillColor: _NcDetailColors.surface2, contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _NcDetailColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: temReprovacao ? _NcDetailColors.red.withValues(alpha: .5) : _NcDetailColors.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: temReprovacao ? _NcDetailColors.red : _NcDetailColors.blue, width: 1.5)),
                        ),
                      ),
                    ],
                  );
                }),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _NcDetailColors.red.withValues(alpha: .1), borderRadius: BorderRadius.circular(8), border: Border.all(color: _NcDetailColors.red.withValues(alpha: .4))), child: Text(_error!, style: const TextStyle(color: _NcDetailColors.red, fontSize: 12))),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: _NcDetailColors.muted, side: const BorderSide(color: _NcDetailColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: _NcDetailColors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: (_loading || (widget.porques.isNotEmpty && _porqueDecisao == null) || ((_decisoes.any((d) => d == 'REJEITADA') || _porqueDecisao == 'REJEITADA') && _comentarioCtrl.text.trim().isEmpty)) ? null : _submit,
                    icon: _loading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Enviar Revisão', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AtividadeRevisaoCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> atividade;
  final String decisao;
  final TextEditingController motivoCtrl;
  final ValueChanged<String> onDecisao;
  const _AtividadeRevisaoCard({required this.index, required this.atividade, required this.decisao, required this.motivoCtrl, required this.onDecisao});

  @override
  Widget build(BuildContext context) {
    final titulo = atividade['titulo'] as String? ?? 'Atividade ${index + 1}';
    final descricao = atividade['descricao'] as String?;
    final isRejeitada = decisao == 'REJEITADA';
    final jaAprovada = (atividade['status'] as String? ?? '').toUpperCase() == 'APROVADA';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRejeitada ? const Color(0xFF2A1A1A) : _NcDetailColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isRejeitada ? _NcDetailColors.red.withValues(alpha: .5) : _NcDetailColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 22, height: 22, alignment: Alignment.center, decoration: BoxDecoration(color: _NcDetailColors.surface, borderRadius: BorderRadius.circular(7), border: Border.all(color: _NcDetailColors.borderStrong)), child: Text('${index + 1}', style: const TextStyle(color: _NcDetailColors.text, fontSize: 11, fontWeight: FontWeight.w900))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(titulo, style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, fontWeight: FontWeight.w800, height: 1.35))),
                        if (jaAprovada && !isRejeitada) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: _NcDetailColors.green.withValues(alpha: .15), borderRadius: BorderRadius.circular(99), border: Border.all(color: _NcDetailColors.green.withValues(alpha: .4))),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.check_circle_outline_rounded, size: 9, color: _NcDetailColors.green),
                              const SizedBox(width: 3),
                              const Text('Já aprovada', style: TextStyle(color: _NcDetailColors.green, fontSize: 9, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ],
                      ],
                    ),
                    if (descricao != null && descricao.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(descricao, style: const TextStyle(color: _NcDetailColors.muted, fontSize: 11, height: 1.35)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ToggleBtn(label: 'Aprovar', icon: Icons.check_circle_outline_rounded, active: !isRejeitada, color: _NcDetailColors.green, onTap: () => onDecisao('APROVADA'))),
              const SizedBox(width: 8),
              Expanded(child: _ToggleBtn(label: 'Reprovar', icon: Icons.cancel_outlined, active: isRejeitada, color: _NcDetailColors.red, onTap: () => onDecisao('REJEITADA'))),
            ],
          ),
          if (isRejeitada) ...[
            const SizedBox(height: 10),
            TextField(
              controller: motivoCtrl,
              maxLines: 3, minLines: 2,
              style: const TextStyle(color: _NcDetailColors.text, fontSize: 12, height: 1.5),
              decoration: InputDecoration(
                hintText: 'Motivo da reprovação desta atividade...',
                hintStyle: const TextStyle(color: _NcDetailColors.muted, fontSize: 12),
                filled: true, fillColor: _NcDetailColors.surface,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _NcDetailColors.red.withValues(alpha: .4))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _NcDetailColors.red.withValues(alpha: .4))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _NcDetailColors.red, width: 1.5)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PorqueRevisaoCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> porque;
  final String decisao;
  final ValueChanged<String> onDecisao;
  const _PorqueRevisaoCard({required this.index, required this.porque, required this.decisao, required this.onDecisao});

  @override
  Widget build(BuildContext context) {
    final pergunta = porque['pergunta'] as String? ?? 'Porquê ${index + 1}';
    final resposta = porque['resposta'] as String?;
    final isRejeitada = decisao == 'REJEITADA';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRejeitada ? const Color(0xFF2A1A1A) : _NcDetailColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isRejeitada ? _NcDetailColors.red.withValues(alpha: .5) : _NcDetailColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 22, height: 22, alignment: Alignment.center, decoration: BoxDecoration(color: _NcDetailColors.blue.withValues(alpha: .2), borderRadius: BorderRadius.circular(7), border: Border.all(color: _NcDetailColors.borderStrong)), child: Text('${index + 1}', style: const TextStyle(color: _NcDetailColors.blue, fontSize: 11, fontWeight: FontWeight.w900))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pergunta, style: const TextStyle(color: _NcDetailColors.muted, fontSize: 11, fontWeight: FontWeight.w700, height: 1.35)),
                    if (resposta != null && resposta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(resposta, style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, height: 1.35)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ToggleBtn(label: 'Aprovar', icon: Icons.check_circle_outline_rounded, active: !isRejeitada, color: _NcDetailColors.green, onTap: () => onDecisao('APROVADA'))),
              const SizedBox(width: 8),
              Expanded(child: _ToggleBtn(label: 'Reprovar', icon: Icons.cancel_outlined, active: isRejeitada, color: _NcDetailColors.red, onTap: () => onDecisao('REJEITADA'))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Revisar Execução Sheet ────────────────────────────────────────────────────
class _RevisarExecucaoSheet extends StatefulWidget {
  final String ncId;
  final List<Map<String, dynamic>> atividades;
  final List<Map<String, dynamic>> atividadesJaAprovadas;
  final List<Map<String, dynamic>> porques;
  final dio_pkg.Dio dio;
  final String? token;
  const _RevisarExecucaoSheet({required this.ncId, required this.atividades, required this.atividadesJaAprovadas, required this.porques, required this.dio, this.token});

  @override
  State<_RevisarExecucaoSheet> createState() => _RevisarExecucaoSheetState();
}

class _RevisarExecucaoSheetState extends State<_RevisarExecucaoSheet> {
  late final List<Map<String, dynamic>> _todasAtividades;
  late final List<bool> _ehJaAprovada;
  late final List<String> _decisoes;
  late final List<TextEditingController> _motivoCtrl;
  final _comentarioCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _todasAtividades = [...widget.atividadesJaAprovadas, ...widget.atividades];
    _ehJaAprovada = [
      ...List.filled(widget.atividadesJaAprovadas.length, true),
      ...List.filled(widget.atividades.length, false),
    ];
    _decisoes = List.filled(_todasAtividades.length, 'APROVADA');
    _motivoCtrl = List.generate(_todasAtividades.length, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _motivoCtrl) c.dispose();
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    for (var i = 0; i < _todasAtividades.length; i++) {
      if (_decisoes[i] == 'REJEITADA' && _motivoCtrl[i].text.trim().isEmpty) {
        setState(() => _error = 'Informe o motivo para cada atividade reprovada.');
        return;
      }
    }
    setState(() { _loading = true; _error = null; });
    try {
      final decisoes = <Map<String, dynamic>>[];
      for (var i = 0; i < _todasAtividades.length; i++) {
        decisoes.add({
          'atividadeId': _todasAtividades[i]['id'] as String,
          'status': _decisoes[i],
          if (_decisoes[i] == 'REJEITADA') 'motivo': _motivoCtrl[i].text.trim(),
        });
      }
      await revisarExecucao(
        widget.dio, widget.ncId, decisoes,
        comentario: _comentarioCtrl.text.trim().isEmpty ? null : _comentarioCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: _NcDetailColors.muted2, borderRadius: BorderRadius.circular(99))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: .15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.verified_outlined, color: Color(0xFF7C3AED), size: 18)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Revisar Execução', style: TextStyle(color: _NcDetailColors.text, fontSize: 17, fontWeight: FontWeight.w900)),
                      Text('Aprove ou reprove a execução de cada atividade', style: TextStyle(color: _NcDetailColors.muted, fontSize: 12, height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: _NcDetailColors.border, height: 1),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              children: [
                const Text('ATIVIDADES EXECUTADAS', style: TextStyle(color: Color(0xFFD7E8FF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4)),
                const SizedBox(height: 8),
                if (_todasAtividades.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Text('Nenhuma atividade para revisar.', style: TextStyle(color: _NcDetailColors.muted, fontSize: 13))))
                else ...[
                  if (widget.atividadesJaAprovadas.isNotEmpty) ...[
                    const Text('JÁ APROVADAS ANTERIORMENTE', style: TextStyle(color: _NcDetailColors.green, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .5)),
                    const SizedBox(height: 6),
                    for (var i = 0; i < widget.atividadesJaAprovadas.length; i++) ...[
                      _ExecucaoRevisaoCard(index: i, atividade: _todasAtividades[i], decisao: _decisoes[i], motivoCtrl: _motivoCtrl[i], onDecisao: (d) => setState(() => _decisoes[i] = d), jaAprovada: true, token: widget.token),
                      const SizedBox(height: 10),
                    ],
                    if (widget.atividades.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      const Text('NOVAS ATIVIDADES', style: TextStyle(color: Color(0xFFD7E8FF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .5)),
                      const SizedBox(height: 6),
                    ],
                  ],
                  for (var i = widget.atividadesJaAprovadas.length; i < _todasAtividades.length; i++) ...[
                    _ExecucaoRevisaoCard(index: i, atividade: _todasAtividades[i], decisao: _decisoes[i], motivoCtrl: _motivoCtrl[i], onDecisao: (d) => setState(() => _decisoes[i] = d), jaAprovada: false, token: widget.token),
                    const SizedBox(height: 10),
                  ],
                ],
                const SizedBox(height: 8),
                const Text('COMENTÁRIO GERAL (opcional)', style: TextStyle(color: Color(0xFFD7E8FF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4)),
                const SizedBox(height: 8),
                TextField(
                  controller: _comentarioCtrl,
                  maxLines: 3, minLines: 2,
                  style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, height: 1.55),
                  decoration: InputDecoration(
                    hintText: 'Observações gerais sobre a revisão da execução...',
                    hintStyle: const TextStyle(color: _NcDetailColors.muted, fontSize: 12),
                    filled: true, fillColor: _NcDetailColors.surface2, contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _NcDetailColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _NcDetailColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _NcDetailColors.red.withValues(alpha: .1), borderRadius: BorderRadius.circular(8), border: Border.all(color: _NcDetailColors.red.withValues(alpha: .4))), child: Text(_error!, style: const TextStyle(color: _NcDetailColors.red, fontSize: 12))),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: _NcDetailColors.muted, side: const BorderSide(color: _NcDetailColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: (_loading || widget.atividades.isEmpty) ? null : _submit,
                    icon: _loading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Enviar Revisão', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExecucaoRevisaoCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> atividade;
  final String decisao;
  final TextEditingController motivoCtrl;
  final ValueChanged<String> onDecisao;
  final bool jaAprovada;
  final String? token;
  const _ExecucaoRevisaoCard({required this.index, required this.atividade, required this.decisao, required this.motivoCtrl, required this.onDecisao, this.jaAprovada = false, this.token});

  void _openViewer(BuildContext ctx, String url, String filename) {
    showDialog(
      context: ctx,
      barrierColor: Colors.black87,
      builder: (_) => _ImageViewerDialog(url: url, token: token, filename: filename),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titulo = atividade['titulo'] as String? ?? 'Atividade ${index + 1}';
    final descExecucao = atividade['descricaoExecucao'] as String?;
    final isRejeitada = decisao == 'REJEITADA';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRejeitada ? const Color(0xFF2A1A1A) : (jaAprovada ? const Color(0xFF0A1F12) : _NcDetailColors.surface2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isRejeitada ? _NcDetailColors.red.withValues(alpha: .5) : (jaAprovada ? _NcDetailColors.green.withValues(alpha: .35) : _NcDetailColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (jaAprovada) ...[
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 12, color: _NcDetailColors.green),
                const SizedBox(width: 5),
                const Text('Já aprovada — pode reprovar se necessário', style: TextStyle(color: _NcDetailColors.green, fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 22, height: 22, alignment: Alignment.center, decoration: BoxDecoration(color: _NcDetailColors.surface, borderRadius: BorderRadius.circular(7), border: Border.all(color: _NcDetailColors.borderStrong)), child: Text('${index + 1}', style: const TextStyle(color: _NcDetailColors.text, fontSize: 11, fontWeight: FontWeight.w900))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, fontWeight: FontWeight.w800, height: 1.35)),
                    if (descExecucao != null && descExecucao.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: _NcDetailColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _NcDetailColors.border)),
                        child: Text(descExecucao, style: const TextStyle(color: _NcDetailColors.muted, fontSize: 11, height: 1.4)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Builder(builder: (ctx) {
            final evs = (atividade['evidencias'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
            if (evs.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: evs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx2, ei) {
                    final url = '${AppConfig.apiBaseUrl}/api/evidencias/${evs[ei]['id']}/download';
                    return GestureDetector(
                      onTap: () => _openViewer(ctx2, url, evs[ei]['nomeArquivo'] as String? ?? 'foto.jpg'),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: token != null
                            ? Image(image: NetworkImage(url, headers: {'Authorization': 'Bearer $token'}), width: 72, height: 72, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 72, height: 72, color: _NcDetailColors.surface, child: const Icon(Icons.broken_image_rounded, color: _NcDetailColors.muted, size: 16)))
                            : Container(width: 72, height: 72, color: _NcDetailColors.surface),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ToggleBtn(label: 'Aprovar', icon: Icons.check_circle_outline_rounded, active: !isRejeitada, color: _NcDetailColors.green, onTap: () => onDecisao('APROVADA'))),
              const SizedBox(width: 8),
              Expanded(child: _ToggleBtn(label: 'Reprovar', icon: Icons.cancel_outlined, active: isRejeitada, color: _NcDetailColors.red, onTap: () => onDecisao('REJEITADA'))),
            ],
          ),
          if (isRejeitada) ...[
            const SizedBox(height: 10),
            TextField(
              controller: motivoCtrl,
              maxLines: 3, minLines: 2,
              style: const TextStyle(color: _NcDetailColors.text, fontSize: 12, height: 1.5),
              decoration: InputDecoration(
                hintText: 'Motivo da reprovação da execução...',
                hintStyle: const TextStyle(color: _NcDetailColors.muted, fontSize: 12),
                filled: true, fillColor: _NcDetailColors.surface,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _NcDetailColors.red.withValues(alpha: .4))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _NcDetailColors.red.withValues(alpha: .4))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _NcDetailColors.red, width: 1.5)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _ToggleBtn({required this.label, required this.icon, required this.active, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: .15) : _NcDetailColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? color : _NcDetailColors.border, width: active ? 1.5 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: active ? color : _NcDetailColors.muted),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: active ? color : _NcDetailColors.muted, fontSize: 12, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

// ── Investigação Sheet ────────────────────────────────────────────────────────
class _InvestigacaoSheet extends StatefulWidget {
  final String ncId;
  final dio_pkg.Dio dio;
  final bool isAjuste;
  final List<Map<String, dynamic>> initialPorques;
  final String? initialCausaRaiz;
  final List<Map<String, dynamic>> initialAtividades;
  final List<Map<String, dynamic>> atividadesAprovadas;

  const _InvestigacaoSheet({
    required this.ncId,
    required this.dio,
    this.isAjuste = false,
    this.initialPorques = const [],
    this.initialCausaRaiz,
    this.initialAtividades = const [],
    this.atividadesAprovadas = const [],
  });

  @override
  State<_InvestigacaoSheet> createState() => _InvestigacaoSheetState();
}

class _InvestigacaoSheetState extends State<_InvestigacaoSheet> {
  final _formKey = GlobalKey<FormState>();
  late final List<_PorqueEntry> _porques;
  late final TextEditingController _causaRaizCtrl;
  late final List<_AtividadeEntry> _atividades;
  late List<Map<String, dynamic>> _aprovadas;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPorques.isNotEmpty) {
      _porques = widget.initialPorques.map((p) {
        final e = _PorqueEntry();
        e.pergunta.text = p['pergunta'] as String? ?? '';
        e.resposta.text = p['resposta'] as String? ?? '';
        return e;
      }).toList();
    } else {
      _porques = [_PorqueEntry()];
    }
    _causaRaizCtrl = TextEditingController(text: widget.initialCausaRaiz ?? '');
    if (widget.initialAtividades.isNotEmpty) {
      _atividades = widget.initialAtividades.map((a) {
        final e = _AtividadeEntry();
        e.titulo.text = a['titulo'] as String? ?? '';
        e.descricao.text = a['descricao'] as String? ?? '';
        e.prazo = a['prazo'] as String? ?? a['dataLimite'] as String?;
        return e;
      }).toList();
    } else {
      _atividades = [_AtividadeEntry()];
    }
    _aprovadas = List.from(widget.atividadesAprovadas);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final payload = {
        'porques': _porques.map((p) => {'pergunta': p.pergunta.text.trim(), 'resposta': p.resposta.text.trim()}).toList(),
        'causaRaiz': _causaRaizCtrl.text.trim(),
        'atividades': _atividades.map((a) => {
          'titulo': a.titulo.text.trim(),
          'descricao': a.descricao.text.trim(),
          'prazo': a.prazo,
        }).toList(),
      };
      await submeterInvestigacao(widget.dio, widget.ncId, payload);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => Form(
          key: _formKey,
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: const Color(0xFF3F4A57), borderRadius: BorderRadius.circular(99)))),
              Text(widget.isAjuste ? 'Ajustar Plano de Ação' : 'Submeter Investigação', style: const TextStyle(color: _NcDetailColors.text, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              // Porquês
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('5 PORQUÊS', style: TextStyle(color: Color(0xFFD7E8FF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4)),
                  if (_porques.length < 5)
                    TextButton.icon(
                      onPressed: () => setState(() => _porques.add(_PorqueEntry())),
                      icon: const Icon(Icons.add, size: 14, color: _NcDetailColors.blue),
                      label: const Text('Adicionar', style: TextStyle(color: _NcDetailColors.blue, fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < _porques.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _NcDetailColors.surface2, borderRadius: BorderRadius.circular(10), border: Border.all(color: _NcDetailColors.border)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(width: 20, height: 20, alignment: Alignment.center, decoration: BoxDecoration(color: _NcDetailColors.blue.withValues(alpha: .2), borderRadius: BorderRadius.circular(6)), child: Text('${i+1}', style: const TextStyle(color: _NcDetailColors.blue, fontSize: 10, fontWeight: FontWeight.w900))),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Pergunta', style: TextStyle(color: _NcDetailColors.muted, fontSize: 11))),
                            if (_porques.length > 1) GestureDetector(onTap: () => setState(() => _porques.removeAt(i)), child: const Icon(Icons.close, size: 16, color: _NcDetailColors.muted)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _Field(ctrl: _porques[i].pergunta, hint: 'Por que ocorreu?', validator: (v) => (v?.isEmpty ?? true) ? 'Obrigatório' : null),
                        const SizedBox(height: 8),
                        const Align(alignment: Alignment.centerLeft, child: Text('Resposta', style: TextStyle(color: _NcDetailColors.muted, fontSize: 11))),
                        const SizedBox(height: 6),
                        _Field(ctrl: _porques[i].resposta, hint: 'Resposta...', validator: (v) => (v?.isEmpty ?? true) ? 'Obrigatório' : null),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const Text('CAUSA RAIZ', style: TextStyle(color: Color(0xFFD7E8FF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4)),
              const SizedBox(height: 8),
              _Field(ctrl: _causaRaizCtrl, hint: 'Descreva a causa raiz...', maxLines: 3, validator: (v) => (v?.isEmpty ?? true) ? 'Obrigatório' : null),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ATIVIDADES', style: TextStyle(color: Color(0xFFD7E8FF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4)),
                  TextButton.icon(
                    onPressed: () => setState(() => _atividades.add(_AtividadeEntry())),
                    icon: const Icon(Icons.add, size: 14, color: _NcDetailColors.blue),
                    label: const Text('Adicionar', style: TextStyle(color: _NcDetailColors.blue, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < _atividades.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _NcDetailColors.surface2, borderRadius: BorderRadius.circular(10), border: Border.all(color: _NcDetailColors.border)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text('Atividade ${i+1}', style: const TextStyle(color: _NcDetailColors.muted, fontSize: 11)),
                            const Spacer(),
                            if (_atividades.length > 1) GestureDetector(onTap: () => setState(() => _atividades.removeAt(i)), child: const Icon(Icons.close, size: 16, color: _NcDetailColors.muted)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _Field(ctrl: _atividades[i].titulo, hint: 'Título da atividade', validator: (v) => (v?.isEmpty ?? true) ? 'Obrigatório' : null),
                        const SizedBox(height: 8),
                        _Field(ctrl: _atividades[i].descricao, hint: 'Descrição...', maxLines: 2, validator: (v) => (v?.isEmpty ?? true) ? 'Obrigatório' : null),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                            if (picked != null) setState(() => _atividades[i].prazo = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(color: _NcDetailColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _NcDetailColors.border)),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 14, color: _NcDetailColors.muted),
                                const SizedBox(width: 8),
                                Text(_atividades[i].prazo != null ? _fmtDate(_atividades[i].prazo) : 'Selecionar prazo', style: TextStyle(color: _atividades[i].prazo != null ? _NcDetailColors.text : _NcDetailColors.muted, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_aprovadas.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('APROVADAS (não precisam de ajuste)', style: TextStyle(color: _NcDetailColors.green, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4)),
                const SizedBox(height: 8),
                for (var i = 0; i < _aprovadas.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2018),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _NcDetailColors.green.withValues(alpha: .4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: _NcDetailColors.green.withValues(alpha: .15), borderRadius: BorderRadius.circular(6)),
                            child: const Icon(Icons.check_circle_rounded, size: 14, color: _NcDetailColors.green),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _aprovadas[i]['titulo'] as String? ?? 'Atividade',
                              style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            onPressed: () {
                              setState(() {
                                final a = _aprovadas.removeAt(i);
                                final entry = _AtividadeEntry();
                                entry.titulo.text = a['titulo'] as String? ?? '';
                                entry.descricao.text = a['descricao'] as String? ?? '';
                                entry.prazo = a['prazo'] as String? ?? a['dataLimite'] as String?;
                                _atividades.add(entry);
                              });
                            },
                            child: const Text('Editar', style: TextStyle(color: _NcDetailColors.blue, fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _NcDetailColors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _loading ? null : _submit,
                  child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(widget.isAjuste ? 'Reenviar Plano Ajustado' : 'Enviar Investigação', style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PorqueEntry {
  final pergunta = TextEditingController();
  final resposta = TextEditingController();
}

class _AtividadeEntry {
  final titulo = TextEditingController();
  final descricao = TextEditingController();
  String? prazo;
}

// ── Execução Sheet ─────────────────────────────────────────────────────────────
class _ExecucaoSheet extends StatefulWidget {
  final String ncId;
  final List<Map<String, dynamic>> atividades;
  final dio_pkg.Dio dio;
  final String? token;
  const _ExecucaoSheet({required this.ncId, required this.atividades, required this.dio, this.token});

  @override
  State<_ExecucaoSheet> createState() => _ExecucaoSheetState();
}

class _ExecucaoSheetState extends State<_ExecucaoSheet> {
  late final List<TextEditingController> _descCtrls;
  late final List<List<File>> _fotos;
  final Set<String> _deletedEvIds = {};
  bool _loading = false;
  String _loadingMsg = '';
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _descCtrls = List.generate(widget.atividades.length, (i) {
      final prev = widget.atividades[i]['descricaoExecucao'] as String? ?? '';
      return TextEditingController(text: prev);
    });
    _fotos = List.generate(widget.atividades.length, (_) => []);
  }

  Future<void> _pickFotos(int index) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF151A21),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: _NcDetailColors.muted2, borderRadius: BorderRadius.circular(99))),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _NcDetailColors.blue.withValues(alpha: .15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.camera_alt_rounded, color: _NcDetailColors.blue, size: 20)),
              title: const Text('Tirar foto', style: TextStyle(color: _NcDetailColors.text, fontWeight: FontWeight.w700)),
              subtitle: const Text('Usar câmera', style: TextStyle(color: _NcDetailColors.muted, fontSize: 12)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _NcDetailColors.blue.withValues(alpha: .15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.photo_library_rounded, color: _NcDetailColors.blue, size: 20)),
              title: const Text('Selecionar da galeria', style: TextStyle(color: _NcDetailColors.text, fontWeight: FontWeight.w700)),
              subtitle: const Text('Múltiplas fotos', style: TextStyle(color: _NcDetailColors.muted, fontSize: 12)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    if (source == ImageSource.camera) {
      final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (photo != null && mounted) setState(() => _fotos[index].add(File(photo.path)));
    } else {
      final photos = await _picker.pickMultiImage(imageQuality: 80);
      if (photos.isNotEmpty && mounted) setState(() => _fotos[index].addAll(photos.map((p) => File(p.path))));
    }
  }

  Future<void> _deleteEvidencia(String evId) async {
    try {
      await widget.dio.patch<void>('/api/evidencias/$evId/desvincular-atividade');
      if (mounted) setState(() => _deletedEvIds.add(evId));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível remover a foto.'), backgroundColor: Colors.red));
    }
  }

  Widget _buildAtividadeCard(int i) {
    final a = widget.atividades[i];
    final titulo = a['titulo'] as String? ?? 'Atividade ${i + 1}';
    final descricaoPlan = a['descricao'] as String? ?? '';
    final statusExec = (a['statusExecucao'] as String? ?? '').toUpperCase();
    final motivoExec = a['motivoRejeicaoExecucao'] as String?;
    final existingEvs = (a['evidencias'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final isAprovada = statusExec == 'APROVADA';
    final isRejeitada = statusExec == 'REJEITADA';
    final isPrimeira = statusExec.isEmpty;

    final borderColor = isAprovada
        ? _NcDetailColors.green.withValues(alpha: .5)
        : isRejeitada
            ? _NcDetailColors.red.withValues(alpha: .5)
            : _NcDetailColors.border;
    final bgColor = isAprovada
        ? const Color(0xFF0D2318)
        : isRejeitada
            ? const Color(0xFF2A1A1A)
            : _NcDetailColors.surface2;
    final accentColor = isAprovada ? _NcDetailColors.green : isRejeitada ? _NcDetailColors.red : const Color(0xFF7C3AED);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: número + título + badge de status anterior
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22, height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: accentColor.withValues(alpha: .2), borderRadius: BorderRadius.circular(7)),
                child: Text('${i + 1}', style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(color: _NcDetailColors.text, fontSize: 13, fontWeight: FontWeight.w800, height: 1.3)),
                  if (descricaoPlan.isNotEmpty)
                    Text(descricaoPlan, style: const TextStyle(color: _NcDetailColors.muted, fontSize: 12, height: 1.4)),
                ],
              )),
              const SizedBox(width: 8),
              if (!isPrimeira)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: accentColor.withValues(alpha: .15), borderRadius: BorderRadius.circular(99), border: Border.all(color: accentColor.withValues(alpha: .4))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isAprovada ? Icons.check_circle_outline_rounded : Icons.cancel_outlined, size: 10, color: accentColor),
                    const SizedBox(width: 3),
                    Text(isAprovada ? 'Aprovada' : 'Reprovada', style: TextStyle(color: accentColor, fontSize: 9, fontWeight: FontWeight.w900)),
                  ]),
                ),
            ],
          ),

          // Motivo de rejeição anterior
          if (isRejeitada && motivoExec != null && motivoExec.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(color: _NcDetailColors.red.withValues(alpha: .08), borderRadius: BorderRadius.circular(8), border: Border.all(color: _NcDetailColors.red.withValues(alpha: .3))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.error_outline_rounded, size: 13, color: _NcDetailColors.red),
                const SizedBox(width: 6),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Motivo da reprovação', style: TextStyle(color: _NcDetailColors.red, fontSize: 10, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(motivoExec, style: const TextStyle(color: _NcDetailColors.red, fontSize: 12, height: 1.4)),
                ])),
              ]),
            ),
          ],

          // Conteúdo read-only para aprovadas / editável para demais
          if (isAprovada) ...[
            const SizedBox(height: 10),
            const Divider(color: _NcDetailColors.border, height: 1),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.lock_outline_rounded, size: 13, color: _NcDetailColors.green),
              const SizedBox(width: 6),
              const Text('Execução aprovada — sem alterações necessárias', style: TextStyle(color: _NcDetailColors.green, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
            if ((a['descricaoExecucao'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _NcDetailColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _NcDetailColors.border)),
                child: Text(a['descricaoExecucao'] as String, style: const TextStyle(color: _NcDetailColors.muted, fontSize: 12, height: 1.4)),
              ),
            ],
          ] else ...[
            const SizedBox(height: 12),
            _Field(ctrl: _descCtrls[i], hint: 'Descreva o que foi feito...', maxLines: 3),
          ],

          // Evidências existentes (rede) — com botão de deleção
          Builder(builder: (_) {
            final visibleEvs = existingEvs.where((ev) => !_deletedEvIds.contains(ev['id'] as String? ?? '')).toList();
            if (visibleEvs.isEmpty || isAprovada) return const SizedBox.shrink();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.photo_library_outlined, size: 12, color: _NcDetailColors.muted),
                const SizedBox(width: 5),
                const Text('EVIDÊNCIAS ANTERIORES', style: TextStyle(color: _NcDetailColors.muted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .4)),
                const SizedBox(width: 4),
                const Text('(toque no × para excluir)', style: TextStyle(color: _NcDetailColors.muted2, fontSize: 9)),
              ]),
              const SizedBox(height: 6),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: visibleEvs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, ei) {
                    final evId = visibleEvs[ei]['id'] as String? ?? '';
                    final url = '${AppConfig.apiBaseUrl}/api/evidencias/$evId/download';
                    return Stack(children: [
                      GestureDetector(
                        onTap: () => showDialog(context: ctx, barrierColor: Colors.black87, builder: (_) => _ImageViewerDialog(url: url, token: widget.token, filename: visibleEvs[ei]['nomeArquivo'] as String? ?? 'foto.jpg')),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: widget.token != null
                              ? Image(image: NetworkImage(url, headers: {'Authorization': 'Bearer ${widget.token}'}), width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: _NcDetailColors.surface, child: const Icon(Icons.broken_image_rounded, color: _NcDetailColors.muted, size: 18)))
                              : Container(width: 80, height: 80, color: _NcDetailColors.surface),
                        ),
                      ),
                      Positioned(
                        top: 2, right: 2,
                        child: GestureDetector(
                          onTap: () => _deleteEvidencia(evId),
                          child: Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(99)), child: const Icon(Icons.close, color: Colors.white, size: 13)),
                        ),
                      ),
                    ]);
                  },
                ),
              ),
            ]);
          }),

          // Novas fotos
          if (!isAprovada) ...[
            const SizedBox(height: 10),
            if (_fotos[i].isNotEmpty) ...[
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _fotos[i].length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, fi) {
                    if (fi == _fotos[i].length) {
                      return GestureDetector(
                        onTap: () => _pickFotos(i),
                        child: Container(width: 80, decoration: BoxDecoration(color: _NcDetailColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _NcDetailColors.border)),
                          child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_rounded, color: _NcDetailColors.blue, size: 22), SizedBox(height: 4), Text('Adicionar', style: TextStyle(color: _NcDetailColors.blue, fontSize: 10, fontWeight: FontWeight.w700))])),
                      );
                    }
                    return Stack(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_fotos[i][fi], width: 80, height: 80, fit: BoxFit.cover)),
                      Positioned(top: 2, right: 2, child: GestureDetector(
                        onTap: () => setState(() => _fotos[i].removeAt(fi)),
                        child: Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(99)), child: const Icon(Icons.close, color: Colors.white, size: 13)),
                      )),
                    ]);
                  },
                ),
              ),
            ] else ...[
              GestureDetector(
                onTap: () => _pickFotos(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: _NcDetailColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _NcDetailColors.border)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_photo_alternate_rounded, color: isRejeitada ? _NcDetailColors.red : _NcDetailColors.blue, size: 18),
                    const SizedBox(width: 8),
                    Text(isRejeitada ? 'Atualizar fotos de evidência' : 'Adicionar fotos de evidência',
                        style: TextStyle(color: isRejeitada ? _NcDetailColors.red : _NcDetailColors.blue, fontSize: 13, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _loadingMsg = 'Enviando fotos...'; });
    try {
      // 1. Envia fotos ANTES do submit para que o backend as inclua no snapshot
      int fotoCount = _fotos.fold(0, (acc, list) => acc + list.length);
      int fotoIdx = 0;
      int uploadErros = 0;
      for (var i = 0; i < widget.atividades.length; i++) {
        final atividadeId = widget.atividades[i]['id'] as String?;
        if (atividadeId == null) continue;
        for (final foto in _fotos[i]) {
          if (!mounted) break;
          fotoIdx++;
          setState(() => _loadingMsg = 'Enviando foto $fotoIdx de $fotoCount...');
          try {
            final formData = dio_pkg.FormData.fromMap({
              'file': await dio_pkg.MultipartFile.fromFile(foto.path),
              'capturedAt': DateTime.now().toUtc().toIso8601String(),
              'origem': 'MOBILE',
            });
            await widget.dio.post<Map<String, dynamic>>(
              '/api/evidencias/atividade/$atividadeId',
              data: formData,
              options: dio_pkg.Options(receiveTimeout: const Duration(seconds: 120)),
            );
          } catch (_) {
            uploadErros++;
          }
        }
      }
      if (uploadErros > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$uploadErros foto(s) não puderam ser enviadas. Verifique a conexão.'), backgroundColor: Colors.orange),
        );
      }

      // 2. Submete execução (backend monta snapshot com as evidências já salvas)
      if (mounted) setState(() => _loadingMsg = 'Enviando execução...');
      final ativs = <Map<String, dynamic>>[];
      for (var i = 0; i < widget.atividades.length; i++) {
        final statusExec = (widget.atividades[i]['statusExecucao'] as String? ?? '').toUpperCase();
        if (statusExec == 'APROVADA') continue;
        ativs.add({'atividadeId': widget.atividades[i]['id'], 'descricaoExecucao': _descCtrls[i].text.trim()});
      }
      await submeterExecucao(widget.dio, widget.ncId, ativs);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() { _loading = false; _loadingMsg = ''; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: const Color(0xFF3F4A57), borderRadius: BorderRadius.circular(99)))),
            const Text('Submeter Execução', style: TextStyle(color: _NcDetailColors.text, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('Descreva como cada atividade foi executada e anexe fotos como evidência.', style: TextStyle(color: _NcDetailColors.muted, fontSize: 12, height: 1.4)),
            const SizedBox(height: 20),
            for (var i = 0; i < widget.atividades.length; i++) ...[
              _buildAtividadeCard(i),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _NcDetailColors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        const SizedBox(width: 10),
                        Text(_loadingMsg, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ])
                    : const Text('Enviar Execução', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;
  const _Field({required this.ctrl, required this.hint, this.maxLines = 1, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: _NcDetailColors.text, fontSize: 13),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _NcDetailColors.muted),
        filled: true,
        fillColor: _NcDetailColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _NcDetailColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _NcDetailColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _NcDetailColors.blue)),
      ),
    );
  }
}

class _EvidenciaCard extends StatelessWidget {
  final Map<String, dynamic> ev;
  final String? token;
  const _EvidenciaCard({required this.ev, this.token});

  void _openViewer(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _ImageViewerDialog(url: url, token: token, filename: ev['nomeArquivo'] as String? ?? 'evidencia.jpg'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = '${AppConfig.apiBaseUrl}/api/evidencias/${ev['id']}/download';
    final lat = ev['latitude'];
    final lon = ev['longitude'];
    final cidade = ev['cidade'] as String?;
    final capturedAt = ev['capturedAt'];
    final hasGeo = lat != null && lon != null;

    return Container(
      decoration: BoxDecoration(
        color: _NcDetailColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _NcDetailColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: token != null ? () => _openViewer(context, url) : null,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: token != null
                          ? Image(
                              image: NetworkImage(url, headers: {'Authorization': 'Bearer $token'}),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: _NcDetailColors.surface,
                                child: const Center(child: Icon(Icons.broken_image_rounded, color: _NcDetailColors.muted, size: 32)),
                              ),
                            )
                          : Container(color: _NcDetailColors.surface, child: const Center(child: CircularProgressIndicator())),
                    ),
                    Positioned(
                      right: 8, bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.open_in_full_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasGeo) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 13, color: _NcDetailColors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          cidade != null && cidade.isNotEmpty
                              ? '$cidade · ${(lat as double).toStringAsFixed(4)}, ${(lon as double).toStringAsFixed(4)}'
                              : '${(lat as double).toStringAsFixed(5)}, ${(lon as double).toStringAsFixed(5)}',
                          style: const TextStyle(color: _NcDetailColors.text, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  if (capturedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(_fmtDateTime(capturedAt.toString()), style: const TextStyle(color: _NcDetailColors.muted, fontSize: 10)),
                    ),
                ] else
                  const Row(
                    children: [
                      Icon(Icons.location_off_rounded, size: 13, color: _NcDetailColors.muted2),
                      SizedBox(width: 4),
                      Text('Sem geolocalização', style: TextStyle(color: _NcDetailColors.muted2, fontSize: 11)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageViewerDialog extends StatefulWidget {
  final String url;
  final String? token;
  final String filename;
  const _ImageViewerDialog({required this.url, this.token, required this.filename});

  @override
  State<_ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<_ImageViewerDialog> {
  bool _downloading = false;
  String? _saved;

  Future<void> _download() async {
    if (_downloading || widget.token == null) return;
    setState(() => _downloading = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/${widget.filename}';
      final d = dio_pkg.Dio();
      await d.download(
        widget.url,
        path,
        options: dio_pkg.Options(headers: {'Authorization': 'Bearer ${widget.token}'}),
      );
      setState(() { _saved = path; _downloading = false; });
    } catch (_) {
      setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: widget.token != null
                  ? Image(
                      image: NetworkImage(widget.url, headers: {'Authorization': 'Bearer ${widget.token}'}),
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(widget.filename, style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
                    ),
                    _downloading
                        ? const SizedBox(width: 40, height: 40, child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                        : IconButton(
                            icon: Icon(_saved != null ? Icons.check_circle_rounded : Icons.download_rounded, color: _saved != null ? Colors.greenAccent : Colors.white),
                            tooltip: 'Baixar',
                            onPressed: _download,
                          ),
                  ],
                ),
              ),
            ),
          ),
          if (_saved != null)
            Positioned(
              bottom: 32, left: 24, right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFF1A2534), borderRadius: BorderRadius.circular(12)),
                child: Text('Salvo em: $_saved', style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
