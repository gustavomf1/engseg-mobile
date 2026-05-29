import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../shared/data/mock_data.dart';
import '../../shared/widgets/prototype_ui.dart';
import '../auth/provider/auth_provider.dart';
import 'model/desvio_action_requests.dart';
import 'model/desvio_detail.dart';
import 'model/evidencia_metadata.dart';
import 'model/trativa_desvio.dart';
import 'repository/desvio_repository_impl.dart';
import 'repository/evidencia_repository_impl.dart';

Widget _photoStrip(List<String> urls) {
  if (urls.isEmpty) return const SizedBox.shrink();
  return SizedBox(
    height: 180,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: urls.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          urls[i],
          width: 240,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 240,
            height: 180,
            color: ProtoColors.surface2,
            child: const Icon(Icons.broken_image_outlined,
                color: ProtoColors.muted, size: 36),
          ),
        ),
      ),
    ),
  );
}

class DesvioDetailPage extends ConsumerWidget {
  final String id;
  const DesvioDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(desvioDetailProvider(id));
    return Scaffold(
      backgroundColor: ProtoColors.bg,
      appBar: AppBar(
        backgroundColor: ProtoColors.bg,
        foregroundColor: ProtoColors.text,
        title: const Text('Desvio'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erro: $e', style: const TextStyle(color: ProtoColors.red)),
        ),
        data: (d) => _Body(d: d),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final DesvioDetail d;
  const _Body({required this.d});
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

  DesvioDetail get d => widget.d;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(desvioDetailProvider(d.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Falha: $e'),
              backgroundColor: ProtoColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider).valueOrNull;
    final isResponsavelTratativa =
        session != null && session.id == d.responsavelTratativaId;
    final isResponsavelDesvio =
        session != null && session.id == d.responsavelDesvioId;
    final isApprover = session != null &&
        (session.isAdmin ||
            session.perfil == 'ENGENHEIRO' ||
            isResponsavelDesvio);
    final canTratar =
        session != null && (session.isAdmin || isResponsavelTratativa);

    final fotos = ref.watch(desvioEvidenciasProvider(d.id)).valueOrNull ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
      children: [
        // Fotos de ocorrência
        if (fotos.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
            child: _photoStrip(fotos),
          ),
          const SizedBox(height: 16),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, fotos.isEmpty ? 12 : 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerCard(),
              const SizedBox(height: 12),
              _infoCard(),
              const SizedBox(height: 16),
              _tratativasSection(),
              const SizedBox(height: 20),
              if (!_busy) ..._actions(canTratar: canTratar, isApprover: isApprover),
              if (_busy) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerCard() {
    return ProtoCard(
      color: const Color(0xFF1A1408),
      border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFF4A390A))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const ProtoPill(
                label: 'Desvio', bg: Color(0xFF4A390A), fg: ProtoColors.yellow),
            const SizedBox(width: 8),
            ProtoPill(
              label: statusLabel[d.status] ?? d.status,
              bg: ProtoColors.surface2,
              fg: ProtoColors.blue,
            ),
          ]),
          const SizedBox(height: 10),
          Text(d.titulo,
              style: const TextStyle(
                  color: ProtoColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  height: 1.3)),
          if (d.dataRegistro.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(d.dataRegistro,
                style: const TextStyle(
                    color: ProtoColors.muted, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _infoCard() {
    return ProtoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (d.orientacaoRealizada != null)
            _line('Orientacao', d.orientacaoRealizada!),
          if (d.localizacaoNome != null) _line('Local', d.localizacaoNome!),
          if (d.responsavelDesvioNome != null)
            _line('Resp. desvio', d.responsavelDesvioNome!),
          if (d.responsavelTratativaNome != null)
            _line('Resp. tratativa', d.responsavelTratativaNome!),
          _line('Registro', d.dataRegistro),
        ],
      ),
    );
  }

  Widget _line(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 110,
            child: Text(k,
                style: const TextStyle(
                    color: ProtoColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          Expanded(
              child: Text(v,
                  style: const TextStyle(
                      color: ProtoColors.text, fontSize: 13))),
        ]),
      );

  Widget _tratativasSection() {
    if (d.tratativas.isEmpty) {
      return const ProtoCard(
        child: Text('Nenhuma tratativa ainda',
            style: TextStyle(color: ProtoColors.muted, fontSize: 13)),
      );
    }
    final byRodada = <int, List<TrativaDesvio>>{};
    for (final t in d.tratativas) {
      byRodada.putIfAbsent(t.rodada, () => []).add(t);
    }
    final rodadas = byRodada.keys.toList()..sort((a, b) => b.compareTo(a));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProtoSectionTitle('Tratativas'),
        const SizedBox(height: 8),
        ...rodadas.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rodada $r',
                      style: const TextStyle(
                          color: ProtoColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  ...byRodada[r]!.map(_tratativaCard),
                ],
              ),
            )),
      ],
    );
  }

  Widget _tratativaCard(TrativaDesvio t) {
    final (bg, fg) = switch (t.status) {
      'APROVADO' => (const Color(0xFF0B3A1C), ProtoColors.green),
      'REPROVADO' => (const Color(0xFF4A1017), ProtoColors.red),
      _ => (ProtoColors.surface2, ProtoColors.blue),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ProtoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(t.titulo,
                    style: const TextStyle(
                        color: ProtoColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ),
              ProtoPill(label: t.status, bg: bg, fg: fg),
            ]),
            const SizedBox(height: 6),
            Text(t.descricao,
                style:
                    const TextStyle(color: ProtoColors.muted, fontSize: 13)),
            if (t.motivoReprovacao != null &&
                t.motivoReprovacao!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Motivo: ${t.motivoReprovacao}',
                  style:
                      const TextStyle(color: ProtoColors.red, fontSize: 12)),
            ],
            if (t.evidencias.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: t.evidencias.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final url = t.evidencias[i].url;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: url != null
                          ? Image.network(url,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _thumbFallback())
                          : _thumbFallback(),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _thumbFallback() => Container(
        width: 64,
        height: 64,
        color: ProtoColors.surface2,
        child: const Icon(Icons.image_outlined, color: ProtoColors.muted),
      );

  List<Widget> _actions(
      {required bool canTratar, required bool isApprover}) {
    switch (d.status) {
      case 'ABERTO':
        if (!canTratar) return [];
        return [
          _primaryButton('Abrir tratativa', () => _run(
              () => ref.read(desvioRepositoryProvider).abrirTratativa(d.id))),
        ];
      case 'AGUARDANDO_TRATATIVA':
        if (!canTratar) return [];
        return [
          _primaryButton('Adicionar tratativa', _openAddTratativa),
          const SizedBox(height: 10),
          if (d.tratativas
              .any((t) => t.rodada == d.rodadaAtual && t.status == 'PENDENTE'))
            _secondaryButton(
                'Submeter tratativas',
                () => _run(() => ref
                    .read(desvioRepositoryProvider)
                    .submeterTratativa(
                        d.id, const SubmeterTrativaDesvioRequest()))),
        ];
      case 'AGUARDANDO_APROVACAO':
        if (!isApprover) return [];
        return [
          _primaryButton(
              'Aprovar',
              () => _run(() => ref
                  .read(desvioRepositoryProvider)
                  .aprovar(d.id, const AprovarDesvioRequest()))),
          const SizedBox(height: 10),
          _secondaryButton('Reprovar', _openReprovar),
        ];
      default:
        return [];
    }
  }

  Widget _primaryButton(String label, VoidCallback onTap) => SizedBox(
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ProtoColors.blue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onTap,
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900)),
        ),
      );

  Widget _secondaryButton(String label, VoidCallback onTap) => SizedBox(
        height: 48,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: ProtoColors.borderStrong),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onTap,
          child: Text(label,
              style: const TextStyle(
                  color: ProtoColors.text, fontWeight: FontWeight.w800)),
        ),
      );

  Future<void> _openAddTratativa() async {
    final result = await showModalBottomSheet<_NovaTratativa>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ProtoColors.surface,
      builder: (_) => const _AddTratativaSheet(),
    );
    if (result == null) return;
    await _run(() async {
      final repo = ref.read(evidenciaRepositoryProvider);
      final ids = <String>[];
      for (final f in result.fotos) {
        final ev = await repo.uploadParaDesvio(
          d.id,
          f,
          EvidenciaMetadata(
            latitude: 0,
            longitude: 0,
            capturedAt: DateTime.now().millisecondsSinceEpoch,
          ),
          tipo: 'TRATATIVA',
        );
        ids.add(ev.id);
      }
      await ref.read(desvioRepositoryProvider).adicionarTratativa(
            d.id,
            AdicionarTrativaRequest(
              titulo: result.titulo,
              descricao: result.descricao,
              evidenciaIds: ids,
            ),
          );
    });
  }

  Future<void> _openReprovar() async {
    final pendentes = d.tratativas
        .where((t) => t.rodada == d.rodadaAtual && t.status == 'PENDENTE')
        .toList();
    final motivos = {
      for (final t in pendentes) t.id: TextEditingController()
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProtoColors.surface,
        title: const Text('Reprovar tratativas',
            style: TextStyle(color: ProtoColors.text)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: pendentes
                .map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.titulo,
                              style: const TextStyle(
                                  color: ProtoColors.text, fontSize: 13)),
                          TextField(
                            controller: motivos[t.id],
                            style:
                                const TextStyle(color: ProtoColors.text),
                            decoration:
                                const InputDecoration(hintText: 'Motivo'),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reprovar')),
        ],
      ),
    );
    if (ok != true) return;
    final itens = pendentes
        .map((t) => ItemReprovacao(
            trativaId: t.id, motivo: motivos[t.id]!.text.trim()))
        .where((i) => i.motivo.isNotEmpty)
        .toList();
    for (final c in motivos.values) {
      c.dispose();
    }
    if (itens.isEmpty) return;
    await _run(() => ref
        .read(desvioRepositoryProvider)
        .reprovar(d.id, ReprovarTrativasDesvioRequest(itens: itens)));
  }
}

class _NovaTratativa {
  final String titulo;
  final String descricao;
  final List<File> fotos;
  const _NovaTratativa(this.titulo, this.descricao, this.fotos);
}

class _AddTratativaSheet extends StatefulWidget {
  const _AddTratativaSheet();
  @override
  State<_AddTratativaSheet> createState() => _AddTratativaSheetState();
}

class _AddTratativaSheetState extends State<_AddTratativaSheet> {
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _fotos = <File>[];
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _take() async {
    final x =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (x != null) setState(() => _fotos.add(File(x.path)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 18, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProtoSectionTitle('Nova tratativa'),
          const SizedBox(height: 12),
          TextField(
            controller: _titulo,
            style: const TextStyle(color: ProtoColors.text),
            decoration: const InputDecoration(hintText: 'Titulo'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descricao,
            maxLines: 2,
            style: const TextStyle(color: ProtoColors.text),
            decoration: const InputDecoration(hintText: 'Descricao'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            ProtoIconButton(icon: Icons.camera_alt_outlined, onTap: _take),
            const SizedBox(width: 10),
            Text('${_fotos.length} foto(s)',
                style:
                    const TextStyle(color: ProtoColors.muted, fontSize: 12)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ProtoColors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (_titulo.text.trim().isEmpty ||
                    _descricao.text.trim().isEmpty ||
                    _fotos.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Titulo, descricao e ao menos 1 foto sao obrigatorios')));
                  return;
                }
                Navigator.pop(
                    context,
                    _NovaTratativa(
                        _titulo.text.trim(), _descricao.text.trim(), _fotos));
              },
              child: const Text('Salvar tratativa',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}
