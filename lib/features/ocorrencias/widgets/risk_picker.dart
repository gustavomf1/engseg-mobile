import 'package:flutter/material.dart';

import '../../../shared/widgets/prototype_ui.dart';

/// Dois seletores segmentados (severidade 1-5, probabilidade 1-4) com label
/// do nível de risco derivado. Reporta valores via callbacks.
class RiskPicker extends StatelessWidget {
  final int severidade;
  final int probabilidade;
  final ValueChanged<int> onSeveridade;
  final ValueChanged<int> onProbabilidade;

  const RiskPicker({
    super.key,
    required this.severidade,
    required this.probabilidade,
    required this.onSeveridade,
    required this.onProbabilidade,
  });

  @override
  Widget build(BuildContext context) {
    final score = severidade * probabilidade;
    final (label, color) = _nivel(score);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProtoSectionTitle('Severidade'),
        const SizedBox(height: 8),
        _Ramp(count: 5, value: severidade, onTap: onSeveridade),
        const SizedBox(height: 16),
        const ProtoSectionTitle('Probabilidade'),
        const SizedBox(height: 8),
        _Ramp(count: 4, value: probabilidade, onTap: onProbabilidade),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text(
              'Nivel de risco',
              style: TextStyle(
                  color: ProtoColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            ProtoPill(
              label: label,
              bg: color.withValues(alpha: .18),
              fg: color,
            ),
          ],
        ),
      ],
    );
  }

  (String, Color) _nivel(int score) {
    if (score >= 15) return ('CRITICO', ProtoColors.red);
    if (score >= 9) return ('ALTO', ProtoColors.orange);
    if (score >= 4) return ('MEDIO', ProtoColors.yellow);
    return ('BAIXO', ProtoColors.green);
  }
}

class _Ramp extends StatelessWidget {
  final int count;
  final int value;
  final ValueChanged<int> onTap;
  const _Ramp({required this.count, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final n = i + 1;
        final active = n <= value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == count - 1 ? 0 : 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onTap(n),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? ProtoColors.blue : ProtoColors.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ProtoColors.border),
                ),
                child: Text(
                  '$n',
                  style: TextStyle(
                    color: active ? Colors.white : ProtoColors.muted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
