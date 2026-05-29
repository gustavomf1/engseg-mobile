import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/prototype_ui.dart';
import '../repository/email_padrao_repository.dart';

/// Widget de formulário que permite ao usuário gerenciar emails de notificação
/// ao criar uma NC ou Desvio. Exibe emails padrão como pills toggleáveis e
/// permite adicionar emails manuais extras.
class EmailEditor extends ConsumerStatefulWidget {
  final String estabelecimentoId;
  final String empresaId;
  final void Function(List<String> manuais, List<String> excluidos) onChanged;

  const EmailEditor({
    super.key,
    required this.estabelecimentoId,
    required this.empresaId,
    required this.onChanged,
  });

  @override
  ConsumerState<EmailEditor> createState() => _EmailEditorState();
}

class _EmailEditorState extends ConsumerState<EmailEditor> {
  final _manuais = <String>[];
  final _excluidos = <String>{};
  final _controller = TextEditingController();

  void _emit() => widget.onChanged(_manuais, _excluidos.toList());

  void _addManual() {
    final v = _controller.text.trim();
    if (v.isEmpty || !v.contains('@')) return;
    setState(() {
      _manuais.add(v);
      _controller.clear();
    });
    _emit();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padraoAsync = ref.watch(emailsPadraoProvider((
      estabelecimentoId: widget.estabelecimentoId,
      empresaId: widget.empresaId,
    )));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProtoSectionTitle('Notificacoes por e-mail'),
        const SizedBox(height: 8),
        padraoAsync.when(
          loading: () => const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: ProtoColors.blue),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (lista) {
            if (lista.isEmpty) return const SizedBox.shrink();
            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: lista.map((e) {
                final excluido = _excluidos.contains(e.email);
                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    setState(() {
                      if (excluido) {
                        _excluidos.remove(e.email);
                      } else {
                        _excluidos.add(e.email);
                      }
                    });
                    _emit();
                  },
                  child: ProtoPill(
                    label: e.email,
                    icon: excluido ? Icons.close_rounded : Icons.check_rounded,
                    bg: excluido ? ProtoColors.surface2 : const Color(0xFF0B3A1C),
                    fg: excluido ? ProtoColors.muted : ProtoColors.green,
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: ProtoColors.text, fontSize: 13),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Adicionar e-mail manual',
                  hintStyle: TextStyle(color: ProtoColors.muted, fontSize: 13),
                  isDense: true,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: ProtoColors.border),
                  ),
                ),
                onSubmitted: (_) => _addManual(),
              ),
            ),
            ProtoIconButton(icon: Icons.add_rounded, onTap: _addManual),
          ],
        ),
        if (_manuais.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _manuais
                .asMap()
                .entries
                .map((entry) => InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        setState(() => _manuais.removeAt(entry.key));
                        _emit();
                      },
                      child: ProtoPill(
                        label: entry.value,
                        icon: Icons.close_rounded,
                        bg: const Color(0xFF1A2A4A),
                        fg: ProtoColors.blue,
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}
