import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../shared/data/mock_data.dart';
import '../../shared/widgets/prototype_ui.dart';
import '../auth/provider/auth_provider.dart';
import 'model/desvio_action_requests.dart';
import 'model/desvio_detail.dart';
import 'model/evidencia_metadata.dart';
import 'model/trativa_desvio.dart';
import 'repository/desvio_repository_impl.dart';
import 'repository/evidencia_repository_impl.dart';

final _jwtTokenProvider = FutureProvider<String?>((ref) async {
  const storage = FlutterSecureStorage();
  return storage.read(key: 'jwt_token');
});

String _formatDate(String iso) {
  try {
    final dt = DateTime.parse(iso);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  } catch (_) {
    return iso;
  }
}

Future<void> _downloadImage(BuildContext context, String url,
    {String? token}) async {
  try {
    final dio = Dio();
    final response = await dio.get<Uint8List>(url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ));
    final dir = await getApplicationDocumentsDirectory();
    final name =
        'desvio_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(response.data!);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Salvo em: ${file.path}'),
          backgroundColor: const Color(0xFF0B3A1C),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao baixar: $e'),
            backgroundColor: const Color(0xFF4A1017)),
      );
    }
  }
}

void _openImageViewer(BuildContext context, List<String> urls, int index,
    {String? token}) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) =>
        _ImageViewer(urls: urls, initialIndex: index, token: token),
  );
}

class _ImageViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  final String? token;
  const _ImageViewer(
      {required this.urls, required this.initialIndex, this.token});
  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late int _current;
  late final PageController _pc;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pc = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.urls.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Baixar',
            onPressed: () => _downloadImage(context, widget.urls[_current],
                token: widget.token),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pc,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Center(
            child: Image(
              image: NetworkImage(
                widget.urls[i],
                headers: widget.token != null
                    ? {'Authorization': 'Bearer ${widget.token}'}
                    : {},
              ),
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white)),
              errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64),
            ),
          ),
        ),
      ),
    );
  }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/desvios'),
        ),
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
  String? get _token => ref.read(_jwtTokenProvider).valueOrNull;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(desvioDetailProvider(d.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha: $e'), backgroundColor: ProtoColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fotos = ref.watch(desvioEvidenciasProvider(d.id)).valueOrNull ?? [];
    final session = ref.watch(authProvider).valueOrNull;
    final token = ref.watch(_jwtTokenProvider).valueOrNull;
    final isResponsavelTratativa =
        session != null && session.id == d.responsavelTratativaId;
    final isResponsavelDesvio =
        session != null && session.id == d.responsavelDesvioId;
    final isCriador = session != null &&
        (session.isAdmin || session.email == d.usuarioCriacaoEmail);
    final isApprover = isResponsavelDesvio;
    final canTratar = session != null && isResponsavelTratativa;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── Cabeçalho ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: const BoxDecoration(
            color: ProtoColors.surface,
            border: Border(bottom: BorderSide(color: ProtoColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const ProtoPill(
                    label: 'Desvio',
                    bg: Color(0xFF4A390A),
                    fg: ProtoColors.yellow),
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
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.3)),
              const SizedBox(height: 6),
              Row(children: [
                if (d.localizacaoNome != null) ...[
                  const Icon(Icons.place_outlined,
                      size: 13, color: ProtoColors.muted),
                  const SizedBox(width: 4),
                  Text(d.localizacaoNome!,
                      style: const TextStyle(
                          color: ProtoColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                ],
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: ProtoColors.muted),
                const SizedBox(width: 4),
                Text(
                  d.dataRegistro.isNotEmpty ? _formatDate(d.dataRegistro) : '—',
                  style: const TextStyle(
                      color: ProtoColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ]),
            ],
          ),
        ),

        // ── Fotos de ocorrência ────────────────────────────────────
        if (fotos.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: _sectionLabel('Evidências da Ocorrência'),
          ),
          SizedBox(
            height: 190,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              scrollDirection: Axis.horizontal,
              itemCount: fotos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () =>
                    _openImageViewer(context, fotos, i, token: token),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image(
                        image: NetworkImage(fotos[i],
                            headers: token != null
                                ? {'Authorization': 'Bearer $token'}
                                : {}),
                        width: 260,
                        height: 190,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 260,
                          height: 190,
                          color: ProtoColors.surface2,
                          child: const Icon(Icons.broken_image_outlined,
                              color: ProtoColors.muted, size: 40),
                        ),
                      ),
                      Positioned(
                        bottom: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.zoom_in_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Identificação ──────────────────────────────────
              _sectionLabel('Identificação'),
              const SizedBox(height: 8),
              ProtoCard(
                child: Column(
                  children: [
                    _row2('Estabelecimento', d.estabelecimentoNome,
                        'Localização', d.localizacaoNome ?? '—'),
                    const Divider(height: 1, color: ProtoColors.border),
                    _row2('Data', d.dataRegistro.isNotEmpty ? _formatDate(d.dataRegistro) : '—',
                        'Registrado por', d.usuarioCriacaoNome ?? '—'),
                    if (d.orientacaoRealizada != null) ...[
                      const Divider(height: 1, color: ProtoColors.border),
                      _rowFull('Orientação Realizada', d.orientacaoRealizada!),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Responsáveis ───────────────────────────────────
              _sectionLabel('Responsáveis'),
              const SizedBox(height: 8),
              ProtoCard(
                child: Row(
                  children: [
                    Expanded(
                        child: _responsavelCell(
                            'RESP. PELO DESVIO',
                            d.responsavelDesvioNome ?? '—')),
                    Container(width: 1, height: 56, color: ProtoColors.border),
                    Expanded(
                        child: _responsavelCell(
                            'RESP. PELA TRATATIVA',
                            d.responsavelTratativaNome ?? '—')),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Tratativas ─────────────────────────────────────
              _tratativasSection(),

              const SizedBox(height: 20),

              // ── Ações ──────────────────────────────────────────
              if (!_busy) ..._actions(canTratar: canTratar, isApprover: isApprover, isCriador: isCriador),
              if (_busy) const Center(child: CircularProgressIndicator()),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) => Text(
        label.toUpperCase(),
        style: const TextStyle(
            color: ProtoColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: .5),
      );

  Widget _row2(String k1, String v1, String k2, String v2) => Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: _cell(k1, v1)),
          Expanded(child: _cell(k2, v2)),
        ]),
      );

  Widget _rowFull(String k, String v) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: _cell(k, v),
      );

  Widget _cell(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: ProtoColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .3)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: ProtoColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      );

  Widget _responsavelCell(String label, String nome) => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: ProtoColors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .4)),
            const SizedBox(height: 6),
            Text(nome,
                style: const TextStyle(
                    color: ProtoColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      );

  Widget _tratativasSection() {
    if (d.tratativas.isEmpty) {
      return ProtoCard(
        child: Row(children: [
          const Icon(Icons.inbox_outlined, color: ProtoColors.muted, size: 18),
          const SizedBox(width: 10),
          const Text('Nenhuma tratativa ainda',
              style: TextStyle(color: ProtoColors.muted, fontSize: 13)),
        ]),
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
        _sectionLabel('Tratativas'),
        const SizedBox(height: 8),
        ...rodadas.map((r) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('Rodada $r',
                      style: const TextStyle(
                          color: ProtoColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w900)),
                ),
                ...byRodada[r]!.map(_tratativaCard),
                const SizedBox(height: 8),
              ],
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
                style: const TextStyle(
                    color: ProtoColors.muted, fontSize: 13)),
            if (t.motivoReprovacao != null && t.motivoReprovacao!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Motivo: ${t.motivoReprovacao}',
                  style: const TextStyle(color: ProtoColors.red, fontSize: 12)),
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
                          ? Image(
                              image: NetworkImage(url,
                                  headers: _token != null
                                      ? {'Authorization': 'Bearer $_token'}
                                      : {}),
                              width: 64, height: 64, fit: BoxFit.cover,
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

  List<Widget> _actions({
    required bool canTratar,
    required bool isApprover,
    required bool isCriador,
  }) {
    switch (d.status) {
      case 'ABERTO':
        if (!isCriador) return [];
        return [
          _btn('Enviar para Tratativa', Icons.send_rounded, ProtoColors.blue,
              () => _run(() => ref.read(desvioRepositoryProvider).abrirTratativa(d.id))),
        ];
      case 'AGUARDANDO_TRATATIVA':
        if (!canTratar) return [];
        return [
          _btn('Adicionar tratativa', Icons.add_rounded, ProtoColors.blue,
              _openAddTratativa),
          const SizedBox(height: 10),
          if (d.tratativas.any((t) => t.rodada == d.rodadaAtual && t.status == 'PENDENTE'))
            _btn('Submeter tratativas', Icons.send_rounded, ProtoColors.green,
                () => _run(() => ref.read(desvioRepositoryProvider).submeterTratativa(
                    d.id, const SubmeterTrativaDesvioRequest()))),
        ];
      case 'AGUARDANDO_APROVACAO':
        if (!isApprover) return [];
        return [
          _btn('Aprovar', Icons.check_circle_outline_rounded, ProtoColors.green,
              () => _run(() => ref.read(desvioRepositoryProvider).aprovar(
                  d.id, const AprovarDesvioRequest()))),
          const SizedBox(height: 10),
          _btn('Reprovar', Icons.cancel_outlined, ProtoColors.red, _openReprovar),
        ];
      default:
        return [];
    }
  }

  Widget _btn(String label, IconData icon, Color color, VoidCallback onTap) =>
      SizedBox(
        height: 50,
        width: double.infinity,
        child: Material(
          color: color.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: .5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Text(label,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 14)),
                ],
              ),
            ),
          ),
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
          d.id, f,
          EvidenciaMetadata(
              latitude: 0,
              longitude: 0,
              capturedAt: DateTime.now().millisecondsSinceEpoch),
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
    final motivos = {for (final t in pendentes) t.id: TextEditingController()};
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
                            style: const TextStyle(color: ProtoColors.text),
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
    for (final c in motivos.values) c.dispose();
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

  Future<void> _addFotos() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: ProtoColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: ProtoColors.muted2, borderRadius: BorderRadius.circular(99)),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: ProtoColors.blue.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.camera_alt_rounded, color: ProtoColors.blue, size: 20),
              ),
              title: const Text('Tirar foto',
                  style: TextStyle(color: ProtoColors.text, fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: ProtoColors.blue.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.photo_library_rounded, color: ProtoColors.blue, size: 20),
              ),
              title: const Text('Selecionar da galeria',
                  style: TextStyle(color: ProtoColors.text, fontWeight: FontWeight.w700)),
              subtitle: const Text('Múltiplas fotos',
                  style: TextStyle(color: ProtoColors.muted, fontSize: 12)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    if (source == ImageSource.camera) {
      final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (x != null) setState(() => _fotos.add(File(x.path)));
    } else {
      final xs = await _picker.pickMultiImage(imageQuality: 85);
      if (xs.isNotEmpty) setState(() => _fotos.addAll(xs.map((x) => File(x.path))));
    }
  }

  Widget _fieldLabel(String label) => Text(
        label,
        style: const TextStyle(
            color: Color(0xFFD7E8FF),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: .4),
      );

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: ProtoColors.muted, fontSize: 13),
        filled: true,
        fillColor: ProtoColors.surface2,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ProtoColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ProtoColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ProtoColors.blue, width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                  color: ProtoColors.muted2, borderRadius: BorderRadius.circular(99)),
            ),
          ),
          const ProtoSectionTitle('Nova tratativa'),
          const SizedBox(height: 16),
          _fieldLabel('TÍTULO *'),
          const SizedBox(height: 6),
          TextField(
            controller: _titulo,
            style: const TextStyle(
                color: ProtoColors.text, fontSize: 14, fontWeight: FontWeight.w600),
            decoration: _fieldDecoration('Ex: Instalação de proteção coletiva'),
          ),
          const SizedBox(height: 14),
          _fieldLabel('DESCRIÇÃO *'),
          const SizedBox(height: 6),
          TextField(
            controller: _descricao,
            maxLines: 4,
            minLines: 3,
            style: const TextStyle(color: ProtoColors.text, fontSize: 13, height: 1.4),
            decoration: _fieldDecoration('Descreva o que foi feito...'),
          ),
          const SizedBox(height: 14),
          _fieldLabel('FOTOS *'),
          const SizedBox(height: 8),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _fotos.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == _fotos.length) {
                  return GestureDetector(
                    onTap: _addFotos,
                    child: Container(
                      width: 84,
                      decoration: BoxDecoration(
                        color: ProtoColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ProtoColors.border),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded,
                              color: ProtoColors.blue, size: 22),
                          SizedBox(height: 4),
                          Text('Adicionar',
                              style: TextStyle(
                                  color: ProtoColors.blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  );
                }
                return Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_fotos[i], width: 84, height: 84, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _fotos.removeAt(i)),
                      child: Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                            color: Colors.black54, borderRadius: BorderRadius.circular(99)),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ]);
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ProtoColors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (_titulo.text.trim().isEmpty ||
                    _descricao.text.trim().isEmpty ||
                    _fotos.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Título, descrição e ao menos 1 foto são obrigatórios'),
                      backgroundColor: ProtoColors.red));
                  return;
                }
                Navigator.pop(context,
                    _NovaTratativa(_titulo.text.trim(), _descricao.text.trim(), List.of(_fotos)));
              },
              child: const Text('Salvar tratativa',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
