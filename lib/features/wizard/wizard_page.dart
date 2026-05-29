import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/providers/capture_provider.dart';
import '../../shared/widgets/prototype_ui.dart';
import '../auth/provider/auth_provider.dart';
import '../ocorrencias/model/criar_desvio_request.dart';
import '../ocorrencias/model/criar_nc_request.dart';
import '../ocorrencias/model/evidencia_metadata.dart';
import '../ocorrencias/model/nc_summary.dart';
import '../ocorrencias/model/norma.dart';
import '../ocorrencias/model/usuario_summary.dart';
import '../ocorrencias/repository/desvio_repository_impl.dart';
import '../ocorrencias/repository/evidencia_repository_impl.dart';
import '../ocorrencias/repository/nc_repository_impl.dart';
import '../ocorrencias/repository/support_repository_impl.dart';

class WizardPage extends ConsumerStatefulWidget {
  final String tipo;
  final Map<String, dynamic>? extra; // fotoPath, latitude, longitude, capturedAt, cidade

  const WizardPage({super.key, required this.tipo, this.extra});

  @override
  ConsumerState<WizardPage> createState() => _WizardPageState();
}

class _WizardPageState extends ConsumerState<WizardPage> {
  late final bool isNc = widget.tipo.toLowerCase() == 'nc';
  late int step = isNc ? 1 : 0;

  // Risk step state
  int severity = 5;
  int probability = 4;
  bool goldenRule = true;

  // Description step state (lifted from _DescriptionStep)
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _orientacaoCtrl = TextEditingController();
  bool _reincidencia = false;
  bool _regraDeOuro = false;

  // Normas selection (IDs)
  final Set<String> _selectedNormaIds = {};

  // Responsável pickers
  UsuarioSummary? _responsavel;
  UsuarioSummary? _responsavelTratativa;

  // NC anterior (reincidência)
  NcSummary? _ncAnterior;

  // Publish state
  bool _publishing = false;
  String? _publishError;

  int get stepCount => isNc ? 6 : 4;

  String get stepTitle {
    if (!isNc) {
      return switch (step) {
        0 => 'Identificação',
        1 => 'Descrição',
        2 => 'Evidências',
        _ => 'Revisão',
      };
    }
    return switch (step) {
      0 => 'Tipo & Local',
      1 => 'Descrição',
      2 => 'Matriz de Risco',
      3 => 'Normas',
      4 => 'Evidências',
      _ => 'Revisão',
    };
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _orientacaoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProtoColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _WizardHeader(
              title: isNc ? 'Nova Nao Conformidade' : 'Novo Desvio',
              subtitle: 'Passo ${step + 1} de $stepCount · $stepTitle',
              step: step,
              total: stepCount,
              onBack: () => context.go('/feed'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                children: [
                  if (step == 0) _TypeLocalStep(isNc: isNc),
                  if (step == 1)
                    _DescriptionStep(
                      isNc: isNc,
                      tituloCtrl: _tituloCtrl,
                      descCtrl: _descCtrl,
                      orientacaoCtrl: _orientacaoCtrl,
                      reincidencia: _reincidencia,
                      regraDeOuro: _regraDeOuro,
                      onReincidencia: (v) => setState(() => _reincidencia = v),
                      onRegraDeOuro: (v) => setState(() => _regraDeOuro = v),
                      responsavel: _responsavel,
                      responsavelTratativa: _responsavelTratativa,
                      onResponsavel: (u) => setState(() => _responsavel = u),
                      onResponsavelTratativa: (u) =>
                          setState(() => _responsavelTratativa = u),
                      ncAnterior: _ncAnterior,
                      onNcAnterior: (nc) => setState(() => _ncAnterior = nc),
                    ),
                  if (isNc && step == 2)
                    _RiskStep(
                      severity: severity,
                      probability: probability,
                      goldenRule: goldenRule,
                      onSeverity: (s) => setState(() => severity = s),
                      onProbability: (p) => setState(() => probability = p),
                      onRule: (v) => setState(() => goldenRule = v),
                    ),
                  if (isNc && step == 3)
                    _NormsStep(
                      selectedIds: _selectedNormaIds,
                      onToggle: (id, selected) => setState(() {
                        if (selected) {
                          _selectedNormaIds.add(id);
                        } else {
                          _selectedNormaIds.remove(id);
                        }
                      }),
                    ),
                  if ((isNc && step == 4) || (!isNc && step == 2))
                    const _EvidenceStep(),
                  if ((isNc && step == 5) || (!isNc && step == 3))
                    _ReviewStep(isNc: isNc),
                ],
              ),
            ),
            _Footer(
              backLabel: step == 0 ? 'Cancelar' : 'Voltar',
              nextLabel: step == stepCount - 1
                  ? (isNc ? 'Publicar como ABERTA' : 'Publicar')
                  : 'Continuar',
              nextIcon: step == stepCount - 1
                  ? Icons.send_outlined
                  : Icons.arrow_forward_rounded,
              onBack: step == 0
                  ? () => context.go('/feed')
                  : () => setState(() => step--),
              onNext: step == stepCount - 1
                  ? _openConfirm
                  : () =>
                      setState(() => step = (step + 1).clamp(0, stepCount - 1)),
            ),
          ],
        ),
      ),
    );
  }

  void _openConfirm() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _ConfirmPublishModal(
        isNc: isNc,
        onPublish: _publicar,
      ),
    );
  }

  Future<void> _publicar() async {
    final workspaceId = ref.read(workspaceProvider)?.estabelecimento.id;
    if (workspaceId == null) {
      throw Exception('Nenhum estabelecimento selecionado');
    }

    final titulo = _tituloCtrl.text.trim();
    final descricao =
        _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();

    if (isNc) {
      final request = CriarNcRequest(
        estabelecimentoId: workspaceId,
        titulo: titulo.isEmpty ? 'Nova NC' : titulo,
        descricao: descricao,
        severidade: severity,
        probabilidade: probability,
        regraDeOuro: goldenRule,
        reincidencia: _reincidencia,
        normaIds: _selectedNormaIds.toList(),
        responsavelNcId: _responsavel?.id,
        responsavelTrativaId: _responsavelTratativa?.id,
        ncAnteriorId: _ncAnterior?.id,
      );
      final nc = await ref.read(ncRepositoryProvider).criar(request);
      await _uploadPhotos(nc.id, isNc: true);
      if (mounted) {
        ref.invalidate(ncListProvider(workspaceId));
        context.go('/oc/${nc.id}');
      }
    } else {
      final orientacao = _orientacaoCtrl.text.trim().isEmpty
          ? null
          : _orientacaoCtrl.text.trim();
      final request = CriarDesvioRequest(
        estabelecimentoId: workspaceId,
        titulo: titulo.isEmpty ? 'Novo Desvio' : titulo,
        descricao: descricao,
        orientacaoRealizada: orientacao,
        regraDeOuro: _regraDeOuro,
        responsavelDesvioId: _responsavel?.id,
        responsavelTratativaId: _responsavelTratativa?.id,
      );
      final desvio = await ref.read(desvioRepositoryProvider).criar(request);
      final desvioId = desvio['id'] as String;
      await _uploadPhotos(desvioId, isNc: false);
      if (mounted) {
        ref.invalidate(desvioListProvider(workspaceId));
        context.go('/desvio/$desvioId');
      }
    }
  }

  Future<void> _uploadPhotos(String id, {required bool isNc}) async {
    final photos = ref.read(captureProvider).map((x) => File(x.path)).toList();
    if (photos.isEmpty) return;
    final extra = widget.extra ?? {};
    final meta = EvidenciaMetadata(
      latitude: (extra['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (extra['longitude'] as num?)?.toDouble() ?? 0,
      capturedAt: (extra['capturedAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      cidade: extra['cidade'] as String?,
    );
    final repo = ref.read(evidenciaRepositoryProvider);
    for (final f in photos) {
      if (isNc) {
        await repo.uploadParaNc(id, f, meta);
      } else {
        await repo.uploadParaDesvio(id, f, meta);
      }
    }
    ref.read(captureProvider.notifier).clear();
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _WizardHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int step;
  final int total;
  final VoidCallback onBack;

  const _WizardHeader({
    required this.title,
    required this.subtitle,
    required this.step,
    required this.total,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      decoration: const BoxDecoration(
          color: ProtoColors.surface,
          border: Border(bottom: BorderSide(color: ProtoColors.border))),
      child: Column(
        children: [
          Row(
            children: [
              ProtoIconButton(icon: Icons.chevron_left_rounded, onTap: onBack),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: ProtoColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            color: ProtoColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              ProtoIconButton(icon: Icons.save_outlined, onTap: () {}),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(total, (i) {
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                      color: i <= step
                          ? ProtoColors.blue
                          : ProtoColors.surface2,
                      borderRadius: BorderRadius.circular(99)),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 0: Type & Local
// ---------------------------------------------------------------------------

class _TypeLocalStep extends StatelessWidget {
  final bool isNc;
  const _TypeLocalStep({required this.isNc});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Tipo'),
        Row(
          children: [
            Expanded(
                child: _TypeBox(
                    title: 'Nao Conformidade',
                    sub: 'Violacao de norma · matriz\n5x5',
                    selected: isNc,
                    color: ProtoColors.red)),
            const SizedBox(width: 8),
            Expanded(
                child: _TypeBox(
                    title: 'Desvio',
                    sub: 'Conduta ou condicao',
                    selected: !isNc,
                    color: ProtoColors.yellow)),
          ],
        ),
        const SizedBox(height: 18),
        const _Label('Estabelecimento'),
        const _SelectRow(
            icon: Icons.business_outlined, text: 'Refinaria Paulinia'),
        const SizedBox(height: 14),
        const _Label('Localizacao especifica'),
        const _SelectRow(
            icon: Icons.place_outlined, text: 'Bloco C - fachada norte'),
        const SizedBox(height: 8),
        Text('GPS capturado: -22.7260, -47.1486 ±3m',
            style: TextStyle(
                color: isNc ? ProtoColors.muted : ProtoColors.orange,
                fontSize: 10,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1: Description — now receives state from parent
// ---------------------------------------------------------------------------

class _DescriptionStep extends ConsumerWidget {
  final bool isNc;
  final TextEditingController tituloCtrl;
  final TextEditingController descCtrl;
  final TextEditingController orientacaoCtrl;
  final bool reincidencia;
  final bool regraDeOuro;
  final ValueChanged<bool> onReincidencia;
  final ValueChanged<bool> onRegraDeOuro;
  final UsuarioSummary? responsavel;
  final UsuarioSummary? responsavelTratativa;
  final ValueChanged<UsuarioSummary?> onResponsavel;
  final ValueChanged<UsuarioSummary?> onResponsavelTratativa;
  final NcSummary? ncAnterior;
  final ValueChanged<NcSummary?> onNcAnterior;

  const _DescriptionStep({
    required this.isNc,
    required this.tituloCtrl,
    required this.descCtrl,
    required this.orientacaoCtrl,
    required this.reincidencia,
    required this.regraDeOuro,
    required this.onReincidencia,
    required this.onRegraDeOuro,
    required this.responsavel,
    required this.responsavelTratativa,
    required this.onResponsavel,
    required this.onResponsavelTratativa,
    required this.ncAnterior,
    required this.onNcAnterior,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(workspaceProvider)?.estabelecimento.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Título'),
        _TextField(
          controller: tituloCtrl,
          hint: isNc
              ? 'Ex: Trabalho em altura sem ancoragem'
              : 'Ex: EPI inadequado em soldagem MIG',
          maxLines: 1,
        ),
        const SizedBox(height: 6),
        const Text('Resumo curto que aparecerá nas listagens',
            style: TextStyle(color: ProtoColors.muted2, fontSize: 11)),
        const SizedBox(height: 22),
        _Label(isNc ? 'Descrição Detalhada' : 'Descrição da Situação'),
        _TextField(
          controller: descCtrl,
          hint: isNc
              ? 'Descreva fato, local e impacto — mínimo 20 caracteres.'
              : 'Descreva a situação observada.',
          maxLines: 5,
          height: 110,
        ),
        const SizedBox(height: 6),
        const Text('Descreva fato, local e impacto — mínimo 20 caracteres.',
            style: TextStyle(color: ProtoColors.muted2, fontSize: 11)),
        if (isNc) ...[
          const SizedBox(height: 22),
          const _Label('Responsáveis'),
          const Text('Eng. Responsável pela Tratativa',
              style: TextStyle(
                  color: ProtoColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          const Text(
              'Quem irá enviar o plano de ação (geralmente EXTERNO)',
              style: TextStyle(color: ProtoColors.muted2, fontSize: 10)),
          const SizedBox(height: 7),
          if (workspaceId != null)
            _UserPickerRow(
              workspaceId: workspaceId,
              selected: responsavelTratativa,
              icon: Icons.manage_accounts_outlined,
              hint: 'Selecionar engenheiro',
              onSelected: onResponsavelTratativa,
            )
          else
            const _SelectRow(
                icon: Icons.manage_accounts_outlined,
                text: 'Selecionar engenheiro'),
          const SizedBox(height: 14),
          const Text('Eng. Responsável pela NC',
              style: TextStyle(
                  color: ProtoColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          const Text('Quem irá validar (aprovar/reprovar) a tratativa',
              style: TextStyle(color: ProtoColors.muted2, fontSize: 10)),
          const SizedBox(height: 7),
          if (workspaceId != null)
            _UserPickerRow(
              workspaceId: workspaceId,
              selected: responsavel,
              icon: Icons.engineering_outlined,
              hint: 'Selecionar engenheiro',
              onSelected: onResponsavel,
            )
          else
            const _SelectRow(
                icon: Icons.engineering_outlined,
                text: 'Selecionar engenheiro'),
          const SizedBox(height: 22),
          const _Label('Sinalizações'),
          _SignalRow(
            checked: reincidencia,
            title: 'Reincidência',
            subtitle:
                'Marque se esta NC é recorrência de uma ocorrência anterior',
            color: ProtoColors.orange,
            onTap: () => onReincidencia(!reincidencia),
          ),
          if (reincidencia) ...[
            const SizedBox(height: 10),
            const Text('NC Anterior',
                style: TextStyle(
                    color: ProtoColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (workspaceId != null)
              ref.watch(ncListProvider(workspaceId)).when(
                    loading: () => const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: ProtoColors.orange)),
                    error: (_, __) => const Text('Erro ao carregar NCs',
                        style: TextStyle(
                            color: ProtoColors.red, fontSize: 12)),
                    data: (ncs) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: ProtoColors.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: ProtoColors.orange.withValues(alpha: .5))),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<NcSummary?>(
                          isExpanded: true,
                          dropdownColor: ProtoColors.surface,
                          value: ncAnterior,
                          hint: const Text('Selecionar NC anterior',
                              style: TextStyle(
                                  color: ProtoColors.muted, fontSize: 13)),
                          style: const TextStyle(
                              color: ProtoColors.text, fontSize: 13),
                          items: [
                            const DropdownMenuItem(
                                value: null,
                                child: Text('— Nenhuma',
                                    style: TextStyle(
                                        color: ProtoColors.muted,
                                        fontSize: 13))),
                            ...ncs.map((nc) => DropdownMenuItem(
                                  value: nc,
                                  child: Text(
                                    '${nc.titulo} · ${nc.status}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                          ],
                          onChanged: onNcAnterior,
                        ),
                      ),
                    ),
                  ),
            if (ncAnterior != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: ProtoColors.orange.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: ProtoColors.orange.withValues(alpha: .3))),
                child: Row(children: [
                  const Icon(Icons.link_rounded,
                      color: ProtoColors.orange, size: 13),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(ncAnterior!.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: ProtoColors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 6),
                  Text(ncAnterior!.status,
                      style: const TextStyle(
                          color: ProtoColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
          ],
          const SizedBox(height: 10),
          _SignalRow(
            checked: regraDeOuro,
            title: 'Regra de Ouro',
            subtitle:
                'Marque se a ocorrência viola uma regra crítica de segurança',
            color: ProtoColors.red,
            onTap: () => onRegraDeOuro(!regraDeOuro),
          ),
        ] else ...[
          const SizedBox(height: 22),
          const _Label('Orientação Realizada'),
          _TextField(
            controller: orientacaoCtrl,
            hint: 'Descreva a orientação dada ao responsável pelo desvio...',
            maxLines: 4,
            height: 88,
          ),
          const SizedBox(height: 6),
          const Text('Obrigatório para publicar.',
              style: TextStyle(color: ProtoColors.muted2, fontSize: 11)),
          const SizedBox(height: 22),
          const _Label('Responsáveis'),
          const Text('Responsável pelo desvio',
              style: TextStyle(
                  color: ProtoColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          if (workspaceId != null)
            _UserPickerRow(
              workspaceId: workspaceId,
              selected: responsavel,
              icon: Icons.person_outline_rounded,
              hint: 'Selecionar responsável',
              onSelected: onResponsavel,
            )
          else
            const _SelectRow(
                icon: Icons.person_outline_rounded,
                text: 'Selecionar responsável'),
          const SizedBox(height: 14),
          const Text('Responsável pela tratativa',
              style: TextStyle(
                  color: ProtoColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          if (workspaceId != null)
            _UserPickerRow(
              workspaceId: workspaceId,
              selected: responsavelTratativa,
              icon: Icons.person_add_alt_outlined,
              hint: 'Selecionar responsável',
              onSelected: onResponsavelTratativa,
            )
          else
            const _SelectRow(
                icon: Icons.person_add_alt_outlined,
                text: 'Selecionar responsável'),
          const SizedBox(height: 22),
          const _Label('Sinalizações'),
          _SignalRow(
            checked: regraDeOuro,
            title: 'Regra de Ouro',
            subtitle:
                'Marque se a ocorrência viola uma regra crítica de segurança',
            color: ProtoColors.red,
            onTap: () => onRegraDeOuro(!regraDeOuro),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// User picker row — Consumer reads usuariosProvider
// ---------------------------------------------------------------------------

class _UserPickerRow extends ConsumerWidget {
  final String workspaceId;
  final UsuarioSummary? selected;
  final IconData icon;
  final String hint;
  final ValueChanged<UsuarioSummary?> onSelected;

  const _UserPickerRow({
    required this.workspaceId,
    required this.selected,
    required this.icon,
    required this.hint,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuariosAsync = ref.watch(usuariosProvider(workspaceId));
    return usuariosAsync.when(
      loading: () => const SizedBox(
          height: 46,
          child: Center(
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)))),
      error: (_, __) => const _SelectRow(
          icon: Icons.error_outline, text: 'Erro ao carregar usuários'),
      data: (usuarios) => GestureDetector(
        onTap: () => _showPicker(context, usuarios),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
              color: ProtoColors.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ProtoColors.border)),
          child: Row(children: [
            Icon(icon, color: ProtoColors.muted, size: 16),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
              selected?.nome ?? hint,
              style: TextStyle(
                  color: selected != null
                      ? ProtoColors.text
                      : ProtoColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w800),
            )),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: ProtoColors.muted, size: 18),
          ]),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, List<UsuarioSummary> usuarios) {
    showModalBottomSheet<UsuarioSummary>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _UserPickerSheet(usuarios: usuarios, selected: selected),
    ).then((u) {
      if (u != null) onSelected(u);
    });
  }
}

class _UserPickerSheet extends StatefulWidget {
  final List<UsuarioSummary> usuarios;
  final UsuarioSummary? selected;
  const _UserPickerSheet({required this.usuarios, required this.selected});

  @override
  State<_UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends State<_UserPickerSheet> {
  String _search = '';
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _search.isEmpty
        ? widget.usuarios
        : widget.usuarios
            .where((u) =>
                u.nome.toLowerCase().contains(_search.toLowerCase()) ||
                u.email.toLowerCase().contains(_search.toLowerCase()))
            .toList();
    return Container(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
          color: ProtoColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(
            child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                    color: ProtoColors.muted,
                    borderRadius: BorderRadius.circular(99)))),
        const SizedBox(height: 16),
        const Align(
            alignment: Alignment.centerLeft,
            child: Text('Selecionar usuário',
                style: TextStyle(
                    color: ProtoColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900))),
        const SizedBox(height: 12),
        Container(
          height: 40,
          decoration: BoxDecoration(
              color: ProtoColors.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ProtoColors.border)),
          child: Row(children: [
            const SizedBox(width: 12),
            const Icon(Icons.search, color: ProtoColors.muted, size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _ctrl,
                onChanged: (v) => setState(() => _search = v),
                style:
                    const TextStyle(color: ProtoColors.text, fontSize: 13),
                decoration: const InputDecoration(
                    hintText: 'Buscar usuário…',
                    hintStyle:
                        TextStyle(color: ProtoColors.muted, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * .4),
          child: ListView(
            shrinkWrap: true,
            children: filtered.map((u) {
              final sel = widget.selected?.id == u.id;
              return GestureDetector(
                onTap: () => Navigator.pop(context, u),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                      color: sel
                          ? ProtoColors.blue.withValues(alpha: .10)
                          : ProtoColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel
                              ? ProtoColors.blue
                              : ProtoColors.border)),
                  child: Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(u.nome,
                              style: TextStyle(
                                  color: sel
                                      ? ProtoColors.blue
                                      : ProtoColors.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                          Text(u.perfil,
                              style: const TextStyle(
                                  color: ProtoColors.muted, fontSize: 11)),
                        ])),
                    if (sel)
                      const Icon(Icons.check_circle,
                          color: ProtoColors.blue, size: 18),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2: Risk
// ---------------------------------------------------------------------------

class _SignalRow extends StatelessWidget {
  final bool checked;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _SignalRow(
      {required this.checked,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: checked
                ? color.withValues(alpha: .07)
                : ProtoColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: checked ? color : ProtoColors.border),
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: checked ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                    color:
                        checked ? color : ProtoColors.borderStrong,
                    width: 1.5),
              ),
              child: checked
                  ? const Icon(Icons.check,
                      color: Colors.white, size: 13)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: TextStyle(
                          color: checked ? color : ProtoColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: ProtoColors.muted,
                          fontSize: 11,
                          height: 1.3)),
                ])),
          ]),
        ),
      );
}

const _sevOpts = [
  (value: 1, label: 'Insignificante', color: Color(0xFF3fb950)),
  (value: 2, label: 'Pequena', color: Color(0xFF3fb950)),
  (value: 3, label: 'Moderada', color: Color(0xFFd29922)),
  (value: 4, label: 'Alta', color: Color(0xFFf97316)),
  (value: 5, label: 'Catastrófica', color: Color(0xFFf85149)),
];

const _probOpts = [
  (value: 1, label: 'Rara', color: Color(0xFF3fb950)),
  (value: 2, label: 'Improvável', color: Color(0xFF3fb950)),
  (value: 3, label: 'Possível', color: Color(0xFFd29922)),
  (value: 4, label: 'Provável', color: Color(0xFFf97316)),
];

Color _riskColor(int score) {
  if (score <= 4) return ProtoColors.green;
  if (score <= 9) return const Color(0xFFDCA31D);
  if (score <= 15) return ProtoColors.orange;
  return ProtoColors.red;
}

String _riskLabel(int score) {
  if (score <= 4) return 'Risco Baixo';
  if (score <= 9) return 'Risco Moderado';
  if (score <= 15) return 'Risco Alto';
  return 'Risco Crítico';
}

class _RiskStep extends StatelessWidget {
  final int severity;
  final int probability;
  final bool goldenRule;
  final ValueChanged<int> onSeverity;
  final ValueChanged<int> onProbability;
  final ValueChanged<bool> onRule;

  const _RiskStep({
    required this.severity,
    required this.probability,
    required this.goldenRule,
    required this.onSeverity,
    required this.onProbability,
    required this.onRule,
  });

  @override
  Widget build(BuildContext context) {
    final score = severity * probability;
    final hasScore = severity > 0 && probability > 0;

    return Column(
      children: [
        ProtoCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('Severidade'),
              _RampPicker(
                  value: severity,
                  options: _sevOpts,
                  onPick: onSeverity),
              const SizedBox(height: 18),
              const _Label('Probabilidade'),
              _RampPicker(
                  value: probability,
                  options: _probOpts,
                  onPick: onProbability),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(
                      child: Text('Matriz de Risco 5×4',
                          style: TextStyle(
                              color: Color(0xFFD7E8FF),
                              fontSize: 13,
                              fontWeight: FontWeight.w900))),
                  Text('SEV × PROB',
                      style: TextStyle(
                          color: ProtoColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              const Row(children: [
                SizedBox(width: 28),
                _Axis('P1'),
                _Axis('P2'),
                _Axis('P3'),
                _Axis('P4')
              ]),
              for (int s = 5; s >= 1; s--)
                Row(
                  children: [
                    SizedBox(
                        width: 28,
                        child: Text('S$s',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: ProtoColors.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w800))),
                    for (int p = 1; p <= 4; p++)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 44,
                          margin: const EdgeInsets.all(2.5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _riskColor(s * p),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: severity == s && probability == p
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: severity == s && probability == p
                                ? [
                                    BoxShadow(
                                        color: Colors.white
                                            .withValues(alpha: .28),
                                        blurRadius: 0,
                                        spreadRadius: 2)
                                  ]
                                : null,
                          ),
                          child: Text('${s * p}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900)),
                        ),
                      ),
                  ],
                ),
              if (hasScore) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: ProtoColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ProtoColors.border)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PONTUAÇÃO',
                                style: TextStyle(
                                    color: ProtoColors.muted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(_riskLabel(score),
                                style: TextStyle(
                                    color: _riskColor(score),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: score),
                        duration: const Duration(milliseconds: 350),
                        builder: (_, v, __) => Text('$v',
                            style: TextStyle(
                                color: _riskColor(score),
                                fontSize: 25,
                                fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        ProtoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('Regra de Ouro'),
              GestureDetector(
                onTap: () => onRule(!goldenRule),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: goldenRule
                        ? ProtoColors.red.withValues(alpha: .07)
                        : ProtoColors.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: goldenRule
                            ? ProtoColors.red
                            : ProtoColors.border),
                  ),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: goldenRule
                            ? ProtoColors.red
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                            color: goldenRule
                                ? ProtoColors.red
                                : ProtoColors.borderStrong,
                            width: 1.5),
                      ),
                      child: goldenRule
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 13)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Regra de Ouro violada',
                              style: TextStyle(
                                  color: goldenRule
                                      ? ProtoColors.red
                                      : ProtoColors.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          const Text(
                              'Marque se a ocorrência viola uma regra crítica de segurança',
                              style: TextStyle(
                                  color: ProtoColors.muted,
                                  fontSize: 11,
                                  height: 1.3)),
                        ])),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RampPicker extends StatelessWidget {
  final int value;
  final List<({int value, String label, Color color})> options;
  final ValueChanged<int> onPick;

  const _RampPicker(
      {required this.value, required this.options, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((o) {
        final active = value == o.value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onPick(o.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? o.color.withValues(alpha: .18)
                    : ProtoColors.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: active ? o.color : ProtoColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${o.value}',
                    style: TextStyle(
                        color: active ? o.color : ProtoColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    o.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: active ? o.color : ProtoColors.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3: Norms — wired to normasProvider
// ---------------------------------------------------------------------------

const _normClauses = <String, List<String>>{
  'NR-35': [
    'Item 35.1 — Estabelece os requisitos mínimos e as medidas de proteção para o trabalho em altura.',
    'Item 35.3.1 — Todo trabalho em altura deve ser realizado com sistema de proteção contra quedas.',
    'Item 35.3.3 — O sistema de proteção deve ser compatível com o tipo de trabalho a ser executado.',
    'Item 35.4.1 — O trabalhador deve ser capacitado para reconhecer os riscos envolvidos.',
  ],
  'NR-06': [
    'Item 6.1 — EPI é todo dispositivo ou produto de uso individual destinado à proteção de riscos.',
    'Item 6.3 — A empresa é obrigada a fornecer EPI adequado ao risco, em perfeito estado de conservação.',
    'Item 6.7 — O empregado é obrigado a usar o EPI apenas para a finalidade a que se destina.',
  ],
  'NR-33': [
    'Item 33.1 — Espaço confinado é qualquer área não projetada para ocupação humana contínua.',
    'Item 33.3.2 — É proibida a entrada sem autorização e sem os procedimentos de segurança estabelecidos.',
    'Item 33.4.1 — O vigia deve permanecer do lado externo do espaço confinado durante toda a atividade.',
  ],
  'NR-10': [
    'Item 10.2.1 — Nos serviços em instalações elétricas é obrigatória a adoção de medidas preventivas de controle do risco elétrico.',
    'Item 10.3.1 — Os trabalhadores autorizados a trabalhar em instalações elétricas devem ser treinados.',
  ],
  'NR-12': [
    'Item 12.1 — Máquinas e equipamentos devem ter dispositivos de partida e parada que reduzam a possibilidade de acidentes.',
    'Item 12.5 — As zonas de perigo das máquinas devem ser protegidas por medidas de proteção coletiva.',
  ],
};

const _iaSuggestions = <String, String>{
  'NR-35':
      'Item 35.3.1 — Todo trabalho em altura deve ser realizado com sistema de proteção contra quedas que contemple EPI e EPC adequados.',
  'NR-06':
      'Item 6.3 — A empresa é obrigada a fornecer aos empregados, gratuitamente, EPI adequado ao risco, em perfeito estado de conservação.',
  'NR-33':
      'Item 33.3.2 — É proibida a entrada de trabalhadores em espaços confinados sem a devida autorização e sem os procedimentos de segurança.',
  'NR-10':
      'Item 10.2.1 — Nos serviços em instalações elétricas é obrigatória a adoção de medidas preventivas de controle do risco elétrico.',
  'NR-12':
      'Item 12.1 — Máquinas e equipamentos devem ter dispositivos de partida, acionamento e parada que reduzam as possibilidades de ocorrência de acidentes.',
};

enum _TrechoMode { search, manual }

class _NormsStep extends ConsumerStatefulWidget {
  final Set<String> selectedIds;
  final void Function(String id, bool selected) onToggle;

  const _NormsStep({required this.selectedIds, required this.onToggle});

  @override
  ConsumerState<_NormsStep> createState() => _NormsStepState();
}

class _NormsStepState extends ConsumerState<_NormsStep> {
  final Map<String, String> _trechos = {};
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggle(Norma norma) {
    final alreadySelected = widget.selectedIds.contains(norma.id);
    widget.onToggle(norma.id, !alreadySelected);
    if (alreadySelected) _trechos.remove(norma.codigo);
  }

  Future<void> _openBusca(String codigo, String nome) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _TrechoSheet(
            code: codigo,
            normName: nome,
            initialMode: _TrechoMode.search,
            existingTrecho: _trechos[codigo]),
      ),
    );
    if (result != null) setState(() => _trechos[codigo] = result);
  }

  Future<void> _openManual(String codigo, String nome) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _TrechoSheet(
            code: codigo,
            normName: nome,
            initialMode: _TrechoMode.manual,
            existingTrecho: _trechos[codigo]),
      ),
    );
    if (result != null) setState(() => _trechos[codigo] = result);
  }

  @override
  Widget build(BuildContext context) {
    final normasAsync = ref.watch(normasProvider);

    return normasAsync.when(
      loading: () => const Center(
          child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator())),
      error: (e, _) => Center(
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text('Erro ao carregar normas: $e',
                  style: const TextStyle(
                      color: ProtoColors.muted, fontSize: 13),
                  textAlign: TextAlign.center))),
      data: (normas) {
        final q = _search.toLowerCase();
        final filtered = _search.isEmpty
            ? normas
            : normas
                .where((n) =>
                    n.codigo.toLowerCase().contains(q) ||
                    n.nome.toLowerCase().contains(q))
                .toList();

        // Codes for selected IDs (for chip display)
        final selectedNormas = normas
            .where((n) => widget.selectedIds.contains(n.id))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Label('Normas / NRs Violadas'),
            if (selectedNormas.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: BoxDecoration(
                    color: ProtoColors.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ProtoColors.border)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('SELECIONADAS',
                      style: TextStyle(
                          color: ProtoColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .6)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: selectedNormas
                        .map((n) => _NormChip(
                            code: n.codigo,
                            onRemove: () => _toggle(n)))
                        .toList(),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
            ],
            Container(
              height: 40,
              decoration: BoxDecoration(
                  color: ProtoColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ProtoColors.border)),
              child: Row(children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, color: ProtoColors.muted, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(
                        color: ProtoColors.text, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar entre ${normas.length} normas…',
                      hintStyle: const TextStyle(
                          color: ProtoColors.muted, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_search.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _search = '');
                    },
                    child: const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(Icons.close,
                            color: ProtoColors.muted, size: 16)),
                  ),
              ]),
            ),
            const SizedBox(height: 10),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                    child: Text(
                        'Nenhuma norma encontrada para "$_search"',
                        style: const TextStyle(
                            color: ProtoColors.muted, fontSize: 13),
                        textAlign: TextAlign.center)),
              )
            else
              ...filtered.map((n) {
                final checked = widget.selectedIds.contains(n.id);
                final trecho = _trechos[n.codigo];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: checked
                          ? ProtoColors.blue.withValues(alpha: .08)
                          : ProtoColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: checked
                              ? ProtoColors.blue
                              : ProtoColors.border),
                    ),
                    child: Column(children: [
                      InkWell(
                        onTap: () => _toggle(n),
                        borderRadius: checked
                            ? const BorderRadius.vertical(
                                top: Radius.circular(10))
                            : BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 13),
                          child: Row(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: checked
                                    ? ProtoColors.blue
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                    color: checked
                                        ? ProtoColors.blue
                                        : ProtoColors.borderStrong,
                                    width: 1.5),
                              ),
                              child: checked
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 13)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(n.codigo,
                                style: TextStyle(
                                    color: checked
                                        ? ProtoColors.blue
                                        : ProtoColors.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(n.nome.toUpperCase(),
                                    style: const TextStyle(
                                        color: ProtoColors.muted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: .3),
                                    overflow: TextOverflow.ellipsis)),
                          ]),
                        ),
                      ),
                      if (checked) ...[
                        Container(height: 1, color: ProtoColors.border),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            if (trecho != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                margin:
                                    const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                    color: ProtoColors.surface2,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                        color: ProtoColors.borderStrong)),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  const Icon(Icons.format_quote,
                                      color: ProtoColors.blue, size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                      child: Text(trecho,
                                          style: const TextStyle(
                                              color: ProtoColors.text,
                                              fontSize: 12,
                                              height: 1.4))),
                                  GestureDetector(
                                      onTap: () => setState(() =>
                                          _trechos.remove(n.codigo)),
                                      child: const Icon(Icons.close,
                                          color: ProtoColors.muted,
                                          size: 14)),
                                ]),
                              ),
                            ],
                            Row(children: [
                              _NormActionBtn(
                                  icon: Icons.search_rounded,
                                  label: 'Buscar trecho',
                                  onTap: () =>
                                      _openBusca(n.codigo, n.nome)),
                              const SizedBox(width: 8),
                              _NormActionBtn(
                                  icon: Icons.edit_outlined,
                                  label: 'Escrever manual',
                                  onTap: () =>
                                      _openManual(n.codigo, n.nome)),
                            ]),
                          ]),
                        ),
                      ],
                    ]),
                  ),
                );
              }),
            const SizedBox(height: 4),
            Text(
              '${normas.length} normas disponíveis${selectedNormas.isNotEmpty ? ' · ${selectedNormas.length} selecionada${selectedNormas.length > 1 ? 's' : ''}' : ''}',
              style:
                  const TextStyle(color: ProtoColors.muted2, fontSize: 11),
            ),
          ],
        );
      },
    );
  }
}

class _NormChip extends StatelessWidget {
  final String code;
  final VoidCallback onRemove;
  const _NormChip({required this.code, required this.onRemove});
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: ProtoColors.blue.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: ProtoColors.blue.withValues(alpha: .45))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(code,
              style: const TextStyle(
                  color: ProtoColors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w900)),
          const SizedBox(width: 5),
          GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close,
                  color: ProtoColors.blue, size: 12)),
        ]),
      );
}

class _NormActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NormActionBtn(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: ProtoColors.surface2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ProtoColors.border)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: ProtoColors.muted, size: 13),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: ProtoColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

// ---------------------------------------------------------------------------
// _TrechoSheet (unchanged logic)
// ---------------------------------------------------------------------------

class _TrechoSheet extends StatefulWidget {
  final String code;
  final String normName;
  final _TrechoMode initialMode;
  final String? existingTrecho;
  const _TrechoSheet(
      {required this.code,
      required this.normName,
      required this.initialMode,
      this.existingTrecho});
  @override
  State<_TrechoSheet> createState() => _TrechoSheetState();
}

class _TrechoSheetState extends State<_TrechoSheet> {
  late _TrechoMode _mode;
  final _searchQueryCtrl = TextEditingController();
  bool _hasSearched = false;
  String? _selectedClause;
  List<String> _searchResults = [];
  final _clauseRefCtrl = TextEditingController();
  late final _textCtrl =
      TextEditingController(text: widget.existingTrecho ?? '');
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _charCount = widget.existingTrecho?.length ?? 0;
    _textCtrl
        .addListener(() => setState(() => _charCount = _textCtrl.text.length));
  }

  @override
  void dispose() {
    _searchQueryCtrl.dispose();
    _clauseRefCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _runSearch() {
    final q = _searchQueryCtrl.text.trim().toLowerCase();
    final all = _normClauses[widget.code] ??
        ['Item 1.1 — Trecho de referência para ${widget.code}.'];
    setState(() {
      _hasSearched = true;
      _selectedClause = null;
      _searchResults = q.isEmpty
          ? all
          : all.where((c) => c.toLowerCase().contains(q)).toList();
      if (_searchResults.isEmpty) {
        _searchResults = [
          _iaSuggestions[widget.code] ??
              'Nenhum trecho encontrado para "$q" em ${widget.code}.'
        ];
      }
    });
  }

  String? get _result {
    if (_mode == _TrechoMode.search) return _selectedClause;
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return null;
    final ref = _clauseRefCtrl.text.trim();
    return ref.isNotEmpty ? '$ref — $text' : text;
  }

  @override
  Widget build(BuildContext context) {
    final isSearch = _mode == _TrechoMode.search;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      decoration: const BoxDecoration(
          color: ProtoColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                      color: ProtoColors.muted,
                      borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 16),
          Row(children: [
            Icon(
                isSearch
                    ? Icons.auto_awesome_rounded
                    : Icons.edit_outlined,
                color: ProtoColors.blue,
                size: 18),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      isSearch
                          ? 'Buscar trecho por IA'
                          : 'Escrever trecho manual',
                      style: const TextStyle(
                          color: ProtoColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w900)),
                  Text(widget.code,
                      style: const TextStyle(
                          color: ProtoColors.muted, fontSize: 12)),
                ])),
            GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: ProtoColors.muted)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _ModeTab(
                label: 'Buscar por IA',
                icon: Icons.auto_awesome_rounded,
                selected: isSearch,
                onTap: () => setState(() {
                      _mode = _TrechoMode.search;
                      _hasSearched = false;
                    })),
            const SizedBox(width: 8),
            _ModeTab(
                label: 'Escrever manual',
                icon: Icons.edit_outlined,
                selected: !isSearch,
                onTap: () => setState(() => _mode = _TrechoMode.manual)),
          ]),
          const SizedBox(height: 16),
          if (isSearch) ...[
            const Text('O que você quer encontrar?',
                style: TextStyle(
                    color: ProtoColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                      color: ProtoColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ProtoColors.border)),
                  child: Row(children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchQueryCtrl,
                        style: const TextStyle(
                            color: ProtoColors.text, fontSize: 13),
                        onSubmitted: (_) => _runSearch(),
                        decoration: const InputDecoration(
                          hintText:
                              'Ex: "linha de vida", "proteção coletiva"…',
                          hintStyle: TextStyle(
                              color: ProtoColors.muted, fontSize: 12),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: ProtoColors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14)),
                  onPressed: _runSearch,
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Buscar',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ]),
            if (_hasSearched) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.of(context).size.height * .28),
                child: ListView(
                  shrinkWrap: true,
                  children: _searchResults.map((clause) {
                    final sel = _selectedClause == clause;
                    return GestureDetector(
                      onTap: () => setState(
                          () => _selectedClause = sel ? null : clause),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? ProtoColors.blue.withValues(alpha: .10)
                              : ProtoColors.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: sel
                                  ? ProtoColors.blue
                                  : ProtoColors.border),
                        ),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Icon(Icons.format_quote,
                              color: sel
                                  ? ProtoColors.blue
                                  : ProtoColors.muted,
                              size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(clause,
                                  style: const TextStyle(
                                      color: ProtoColors.text,
                                      fontSize: 12,
                                      height: 1.4))),
                          if (sel)
                            const Icon(Icons.check_circle,
                                color: ProtoColors.blue, size: 16),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ] else ...[
            const Text('Cláusula / Item',
                style: TextStyle(
                    color: ProtoColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('opcional',
                style:
                    TextStyle(color: ProtoColors.muted, fontSize: 11)),
            const SizedBox(height: 8),
            Container(
              height: 44,
              decoration: BoxDecoration(
                  color: ProtoColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ProtoColors.border)),
              child: TextField(
                controller: _clauseRefCtrl,
                style: const TextStyle(
                    color: ProtoColors.text, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Ex: 12.38, item 4.2…',
                  hintStyle:
                      TextStyle(color: ProtoColors.muted, fontSize: 13),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Row(children: [
              Text('Texto do trecho',
                  style: TextStyle(
                      color: ProtoColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              SizedBox(width: 6),
              Text('*',
                  style: TextStyle(
                      color: ProtoColors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                  color: ProtoColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ProtoColors.border)),
              child: TextField(
                controller: _textCtrl,
                maxLines: 5,
                style: const TextStyle(
                    color: ProtoColors.text,
                    fontSize: 13,
                    height: 1.4),
                decoration: const InputDecoration(
                  hintText: 'Cole ou escreva o trecho da norma aqui…',
                  hintStyle:
                      TextStyle(color: ProtoColors.muted, fontSize: 13),
                  contentPadding: EdgeInsets.all(14),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('$_charCount caracteres',
                style: const TextStyle(
                    color: ProtoColors.muted2, fontSize: 11)),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: SizedBox(
              height: 46,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: ProtoColors.text,
                    side:
                        const BorderSide(color: ProtoColors.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar',
                    style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(
                flex: 2,
                child: SizedBox(
              height: 46,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: _result != null
                        ? ProtoColors.blue
                        : ProtoColors.surface2,
                    foregroundColor: _result != null
                        ? Colors.white
                        : ProtoColors.muted,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: _result != null
                    ? () => Navigator.pop(context, _result)
                    : null,
                icon: const Icon(Icons.link_rounded, size: 16),
                label: const Text('Adicionar trecho',
                    style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            )),
          ]),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeTab(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? ProtoColors.blue.withValues(alpha: .15)
                : ProtoColors.surface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: selected ? ProtoColors.blue : ProtoColors.border),
          ),
          child:
              Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                color: selected ? ProtoColors.blue : ProtoColors.muted,
                size: 14),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected
                        ? ProtoColors.blue
                        : ProtoColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

// ---------------------------------------------------------------------------
// Step 4: Evidence
// ---------------------------------------------------------------------------

class _EvidenceStep extends StatelessWidget {
  const _EvidenceStep();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Evidencias fotograficas · 4'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 10,
          childAspectRatio: .82,
          children: [
            for (int i = 0; i < 4; i++) const _PhotoTile(captured: true),
            const _PhotoTile(),
            const _PhotoTile(add: true),
            const _PhotoTile(add: true),
          ],
        ),
        const SizedBox(height: 10),
        const Text('As 4 fotos foram capturadas com GPS automatico.',
            style: TextStyle(color: ProtoColors.muted2, fontSize: 12)),
        const SizedBox(height: 22),
        const _Label('Data Limite para Tratativa'),
        const _SelectRow(
            icon: Icons.calendar_month_outlined, text: '17/06/2026'),
        const SizedBox(height: 6),
        const Text('Prazo padrão: 30 dias a partir do registro',
            style: TextStyle(color: ProtoColors.muted2, fontSize: 11)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 5: Review
// ---------------------------------------------------------------------------

class _ReviewStep extends StatelessWidget {
  final bool isNc;

  const _ReviewStep({required this.isNc});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ProtoCard(
          color: Color(0xFF1A2534),
          border: Border.fromBorderSide(BorderSide(color: ProtoColors.blue)),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: ProtoColors.blue, size: 36),
              SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                Text('Tudo pronto para publicar',
                    style: TextStyle(
                        color: ProtoColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text(
                    'Revise os dados abaixo. Voce podera editar campos nao-criticos depois da publicacao.',
                    style: TextStyle(
                        color: ProtoColors.muted,
                        fontSize: 12,
                        height: 1.3))
              ])),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ProtoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isNc ? 'NC' : 'DESVIO',
                  style: const TextStyle(
                      color: ProtoColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Text(
                  isNc
                      ? 'Trabalho em altura sem ancoragem dupla na\nfachada do bloco C'
                      : 'EPI inadequado em soldagem MIG — luva sem\nproteção térmica',
                  style: const TextStyle(
                      color: ProtoColors.text,
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              const _ReviewLine('Estabelecimento', 'Refinaria Paulínia'),
              const _ReviewLine('Local', 'Bloco C - fachada norte'),
              if (isNc) ...[
                const _ReviewLine('Risco', 'Crítico · 20', red: true),
                const _ReviewLine('Normas', 'NR-35'),
                const _ReviewLine('Eng. construtora', 'Felipe Tanaka'),
                const _ReviewLine('Eng. verificação', 'A definir'),
                const _ReviewLine('Reincidência', 'Não'),
              ] else ...[
                const _ReviewLine('Orientação realizada', 'Sim'),
                const _ReviewLine('Resp. desvio', 'A definir'),
                const _ReviewLine('Resp. tratativa', 'A definir'),
                const _ReviewLine('Regra de ouro', 'Não'),
              ],
              const _ReviewLine('Evidências', '4 fotos · GPS'),
              const _ReviewLine('Prazo', '13/05/2026'),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// ConfirmPublishModal — receives onPublish callback
// ---------------------------------------------------------------------------

class _ConfirmPublishModal extends StatefulWidget {
  final bool isNc;
  final Future<void> Function() onPublish;

  const _ConfirmPublishModal(
      {required this.isNc, required this.onPublish});

  @override
  State<_ConfirmPublishModal> createState() => _ConfirmPublishModalState();
}

class _ConfirmPublishModalState extends State<_ConfirmPublishModal> {
  int stage = 0;
  String? errorMsg;

  Future<void> _send() async {
    setState(() {
      stage = 1;
      errorMsg = null;
    });
    try {
      await widget.onPublish();
      if (mounted) setState(() => stage = 2);
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          stage = 0;
          errorMsg = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                    color: ProtoColors.bg.withValues(alpha: .70)))),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            decoration: const BoxDecoration(
                color: ProtoColors.surface,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(22))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                        color: ProtoColors.muted,
                        borderRadius: BorderRadius.circular(99))),
                const SizedBox(height: 22),
                if (stage == 0) ...[
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('REVISAO FINAL',
                          style: TextStyle(
                              color: ProtoColors.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.w900))),
                  const SizedBox(height: 8),
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Confirmar publicacao?',
                          style: TextStyle(
                              color: ProtoColors.text,
                              fontSize: 21,
                              fontWeight: FontWeight.w900))),
                  const SizedBox(height: 18),
                  ProtoCard(
                    color: ProtoColors.surface2,
                    child: Column(children: [
                      _ReviewRow('Tipo',
                          widget.isNc ? 'Nao Conformidade' : 'Desvio'),
                      _ReviewRow(
                          'Titulo',
                          widget.isNc
                              ? 'Trabalho em altura sem\nancoragem dupla na fachada do\nbloco C'
                              : 'EPI inadequado em soldagem\nMIG — luva sem protecao termica'),
                      const _ReviewRow('Local', 'Bloco C - fachada norte'),
                      if (widget.isNc)
                        const _ReviewRow('Risco', 'Critico · 20',
                            red: true),
                      const _ReviewRow('Evidencias', '4 fotos · GPS'),
                      if (!widget.isNc)
                        const _ReviewRow(
                            'Notificacoes', '2 destinatarios'),
                    ]),
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: ProtoColors.red.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: ProtoColors.red.withValues(alpha: .4))),
                      child: Row(children: [
                        const Icon(Icons.error_outline,
                            color: ProtoColors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(errorMsg!,
                                style: const TextStyle(
                                    color: ProtoColors.red,
                                    fontSize: 12))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                        child: _FooterButton(
                            label: 'Voltar',
                            onTap: () => Navigator.pop(context),
                            primary: false)),
                    const SizedBox(width: 8),
                    Expanded(
                        flex: 2,
                        child: _FooterButton(
                            label: 'Publicar',
                            icon: Icons.send_outlined,
                            onTap: _send)),
                  ]),
                ] else if (stage == 1) ...[
                  const SizedBox(height: 22),
                  const _SendingEnvelope(),
                  const SizedBox(height: 18),
                  const Text('Publicando...',
                      style: TextStyle(
                          color: ProtoColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 22),
                  const _ProgressLine(done: true, label: 'Validando dados'),
                  const _ProgressLine(
                      done: true,
                      label: 'Enviando 4 evidencias (3.4 MB)'),
                  const _ProgressLine(
                      done: false,
                      label: 'Notificando responsaveis via push',
                      active: true),
                  const _ProgressLine(
                      done: false, label: 'Gerando protocolo'),
                  const SizedBox(height: 20),
                ] else ...[
                  Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                          color: ProtoColors.green.withValues(alpha: .16),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color:
                                  ProtoColors.green.withValues(alpha: .45),
                              width: 2)),
                      child: const Icon(Icons.check_rounded,
                          color: ProtoColors.green, size: 36)),
                  const SizedBox(height: 18),
                  const Text('Publicada com sucesso!',
                      style: TextStyle(
                          color: ProtoColors.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          color: ProtoColors.surface2,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                          widget.isNc ? 'NC-2026-0289' : 'DS-2026-0934',
                          style: const TextStyle(
                              color: ProtoColors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1))),
                  const SizedBox(height: 18),
                  Text(
                      widget.isNc
                          ? 'Felipe Tanaka e Marcos Silva foram\nnotificados via push.'
                          : 'Felipe Tanaka e Marcos Silva foram\nnotificados via push. Voce pode\nacompanhar o andamento em\n"Ocorrencias".',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: ProtoColors.muted,
                          fontSize: 13,
                          height: 1.4)),
                  const SizedBox(height: 18),
                  if (widget.isNc)
                    _FooterButton(
                        label: 'OK', onTap: () => context.go('/feed'))
                  else
                    Row(
                      children: [
                        Expanded(
                            child: _FooterButton(
                                label: 'Ver detalhes',
                                onTap: () =>
                                    context.go('/oc/DS-2026-0931'),
                                primary: false)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _FooterButton(
                                label: 'Concluir',
                                onTap: () => context.go('/feed'))),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Misc widgets
// ---------------------------------------------------------------------------

class _SendingEnvelope extends StatelessWidget {
  const _SendingEnvelope();
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: .88, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        builder: (_, v, __) => Transform.scale(
            scale: v,
            child: Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: ProtoColors.blue.withValues(alpha: .35),
                        width: 2)),
                child: const Icon(Icons.mail_outline_rounded,
                    color: ProtoColors.blue, size: 48))),
      );
}

class _ProgressLine extends StatelessWidget {
  final bool done;
  final bool active;
  final String label;
  const _ProgressLine(
      {required this.done, required this.label, this.active = false});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(children: [
        Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
                color: done
                    ? ProtoColors.green
                    : (active ? ProtoColors.blue : ProtoColors.surface2),
                shape: BoxShape.circle),
            child: Icon(done ? Icons.check : Icons.more_horiz,
                color: Colors.white, size: 13)),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                color: active || done
                    ? ProtoColors.text
                    : ProtoColors.muted2,
                fontSize: 13,
                fontWeight: FontWeight.w700))
      ]));
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final double? height;

  const _TextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget field = TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
          color: ProtoColors.text, fontSize: 14, height: 1.3),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: ProtoColors.muted, fontSize: 14),
        contentPadding: const EdgeInsets.all(15),
        border: InputBorder.none,
      ),
    );
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
          color: ProtoColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ProtoColors.border)),
      child: field,
    );
  }
}

class _Axis extends StatelessWidget {
  final String text;
  const _Axis(this.text);
  @override
  Widget build(BuildContext context) => Expanded(
      child: Center(
          child: Text(text,
              style: const TextStyle(
                  color: ProtoColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800))));
}

class _PhotoTile extends StatelessWidget {
  final bool captured;
  final bool add;
  const _PhotoTile({this.captured = false, this.add = false});
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          color: ProtoColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color:
                  captured ? Colors.transparent : ProtoColors.border)),
      child: Stack(children: [
        if (captured)
          Positioned.fill(
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(colors: [
                        ProtoColors.surface2,
                        ProtoColors.bg.withValues(alpha: .6)
                      ])))),
        Center(
            child: Icon(
                add
                    ? Icons.add_photo_alternate_outlined
                    : Icons.camera_alt_outlined,
                color: ProtoColors.muted,
                size: 24)),
        if (!captured)
          Center(
              child: Padding(
                  padding: const EdgeInsets.only(top: 44),
                  child: Text(add ? 'Adicionar' : 'Tirar foto',
                      style: const TextStyle(
                          color: ProtoColors.muted, fontSize: 11)))),
        if (captured)
          Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .72),
                      borderRadius: BorderRadius.circular(6)),
                  child: const Text('GPS',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900))))
      ]));
}

class _ReviewLine extends StatelessWidget {
  final String label;
  final String value;
  final bool red;
  const _ReviewLine(this.label, this.value, {this.red = false});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: ProtoColors.muted, fontSize: 13))),
        Text(value,
            style: TextStyle(
                color: red ? ProtoColors.red : ProtoColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w900))
      ]));
}

class _ReviewRow extends StatelessWidget {
  final String k;
  final String v;
  final bool red;
  const _ReviewRow(this.k, this.v, {this.red = false});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: Text(k,
                style: const TextStyle(
                    color: ProtoColors.muted, fontSize: 12))),
        Flexible(
            child: Text(v,
                textAlign: TextAlign.end,
                style: TextStyle(
                    color: red ? ProtoColors.red : ProtoColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w900)))
      ]));
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              color: ProtoColors.muted,
              fontSize: 12,
              letterSpacing: .45,
              fontWeight: FontWeight.w900)));
}

class _TypeBox extends StatelessWidget {
  final String title, sub;
  final bool selected;
  final Color color;
  const _TypeBox(
      {required this.title,
      required this.sub,
      required this.selected,
      required this.color});
  @override
  Widget build(BuildContext context) => ProtoCard(
      color: selected
          ? color.withValues(alpha: .10)
          : ProtoColors.surface,
      border: Border.all(
          color: selected ? color : ProtoColors.border),
      child: SizedBox(
          height: 52,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(title,
                style: TextStyle(
                    color: selected ? color : ProtoColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(sub,
                style: const TextStyle(
                    color: ProtoColors.muted,
                    fontSize: 9,
                    height: 1.25))
          ])));
}

class _SelectRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SelectRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: ProtoColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ProtoColors.border)),
      child: Row(children: [
        Icon(icon, color: ProtoColors.muted, size: 16),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: ProtoColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800))),
        const Icon(Icons.keyboard_arrow_down_rounded,
            color: ProtoColors.muted, size: 18)
      ]));
}

class _Footer extends StatelessWidget {
  final String backLabel, nextLabel;
  final IconData nextIcon;
  final VoidCallback onBack, onNext;
  const _Footer(
      {required this.backLabel,
      required this.nextLabel,
      required this.nextIcon,
      required this.onBack,
      required this.onNext});
  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
                color: ProtoColors.surface,
                border: Border(top: BorderSide(color: ProtoColors.border))),
            child: Row(children: [
              Expanded(
                  child: _FooterButton(
                      label: backLabel, onTap: onBack, primary: false)),
              const SizedBox(width: 8),
              Expanded(
                  flex: 2,
                  child: _FooterButton(
                      label: nextLabel, icon: nextIcon, onTap: onNext))
            ])),
        Container(
            width: 100,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(99)))
      ]);
}

class _FooterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final IconData? icon;
  const _FooterButton(
      {required this.label,
      required this.onTap,
      this.primary = true,
      this.icon});
  @override
  Widget build(BuildContext context) => SizedBox(
      height: 48,
      child: FilledButton.icon(
          style: FilledButton.styleFrom(
              backgroundColor:
                  primary ? ProtoColors.blue : ProtoColors.surface2,
              foregroundColor:
                  primary ? Colors.white : ProtoColors.text,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          onPressed: onTap,
          icon: primary
              ? Icon(icon ?? Icons.arrow_forward_rounded, size: 16)
              : const SizedBox.shrink(),
          label: Text(label,
              maxLines: 1,
              style:
                  const TextStyle(fontWeight: FontWeight.w900))));
}
