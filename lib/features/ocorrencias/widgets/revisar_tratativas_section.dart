import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/prototype_ui.dart';
import '../model/desvio_action_requests.dart';
import '../model/desvio_detail.dart';
import '../model/trativa_desvio.dart';
import '../repository/desvio_repository_impl.dart';

/// Seção de revisão de tratativas exibida ao aprovador quando o Desvio está
/// AGUARDANDO_APROVACAO. Cada tratativa pendente pode ser marcada como
/// "Reprovar" (com motivo obrigatório); se nenhuma for marcada, um comentário
/// opcional pode ser informado para a aprovação total.
class RevisarTratativasSection extends ConsumerStatefulWidget {
  final DesvioDetail d;
  final String? token;
  final Future<void> Function(Future<void> Function() action) runAction;

  const RevisarTratativasSection({
    super.key,
    required this.d,
    required this.token,
    required this.runAction,
  });

  @override
  ConsumerState<RevisarTratativasSection> createState() =>
      _RevisarTratativasSectionState();
}

class _RevisarTratativasSectionState
    extends ConsumerState<RevisarTratativasSection> {
  late final List<TrativaDesvio> _pendentes;
  late final Map<String, bool> _reprovarMarcado;
  late final Map<String, TextEditingController> _motivoControllers;
  late final TextEditingController _comentarioController;

  @override
  void initState() {
    super.initState();
    _pendentes = widget.d.tratativas
        .where((t) =>
            t.rodada == widget.d.rodadaAtual && t.status == 'PENDENTE')
        .toList();
    _reprovarMarcado = {for (final t in _pendentes) t.id: false};
    _motivoControllers = {
      for (final t in _pendentes) t.id: TextEditingController(),
    };
    _comentarioController = TextEditingController();
  }

  @override
  void dispose() {
    for (final c in _motivoControllers.values) {
      c.dispose();
    }
    _comentarioController.dispose();
    super.dispose();
  }

  bool get _algumaMarcada => _reprovarMarcado.values.any((v) => v);

  @override
  Widget build(BuildContext context) {
    final marcadas = _reprovarMarcado.values.where((v) => v).length;
    return ProtoCard(
      border: Border.all(color: ProtoColors.blue, width: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProtoSectionTitle('Revisar Tratativas'),
          const SizedBox(height: 4),
          const Text(
            'Marque as que devem ser reprovadas e informe o motivo',
            style: TextStyle(color: ProtoColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          ..._pendentes.map(_itemCard),
          if (!_algumaMarcada) ...[
            const Text(
              'COMENTÁRIO (OPCIONAL)',
              style: TextStyle(
                color: Color(0xFFD7E8FF),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: .4,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _comentarioController,
              style: const TextStyle(color: ProtoColors.text, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Observações sobre a aprovação...',
                hintStyle:
                    const TextStyle(color: ProtoColors.muted, fontSize: 12),
                filled: true,
                fillColor: ProtoColors.surface2,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: ProtoColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: ProtoColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: ProtoColors.blue, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _algumaMarcada ? ProtoColors.red : ProtoColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {},
              child: Text(
                _algumaMarcada
                    ? 'Reprovar $marcadas tratativa(s)'
                    : 'Aprovar Todas',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(TrativaDesvio t) {
    final marcado = _reprovarMarcado[t.id] ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ProtoCard(
        border:
            Border.all(color: marcado ? ProtoColors.red : ProtoColors.border),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.titulo,
                        style: const TextStyle(
                          color: ProtoColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.descricao,
                        style: const TextStyle(
                          color: ProtoColors.muted,
                          fontSize: 13,
                        ),
                      ),
                      if (t.evidencias.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 56,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: t.evidencias.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 6),
                            itemBuilder: (_, i) {
                              final url = t.evidencias[i].url;
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: url != null
                                    ? Image(
                                        image: NetworkImage(
                                          url,
                                          headers: widget.token != null
                                              ? {
                                                  'Authorization':
                                                      'Bearer ${widget.token}',
                                                }
                                              : {},
                                        ),
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _thumbFallback(),
                                      )
                                    : _thumbFallback(),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: marcado,
                      activeColor: ProtoColors.red,
                      onChanged: (v) => setState(
                          () => _reprovarMarcado[t.id] = v ?? false),
                    ),
                    const Text(
                      'Reprovar',
                      style: TextStyle(
                        color: ProtoColors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (marcado) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _motivoControllers[t.id],
                maxLines: 2,
                style: const TextStyle(color: ProtoColors.text, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Motivo da reprovação (obrigatório)',
                  hintStyle: const TextStyle(
                      color: ProtoColors.muted, fontSize: 12),
                  filled: true,
                  fillColor: ProtoColors.surface2,
                  contentPadding: const EdgeInsets.all(10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: ProtoColors.red),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: ProtoColors.red),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: ProtoColors.red, width: 1.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _thumbFallback() => Container(
        width: 56,
        height: 56,
        color: ProtoColors.surface2,
        child: const Icon(Icons.image_outlined, color: ProtoColors.muted),
      );
}
