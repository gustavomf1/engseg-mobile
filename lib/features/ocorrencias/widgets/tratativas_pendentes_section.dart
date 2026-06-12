import 'package:flutter/material.dart';

import '../../../shared/widgets/prototype_ui.dart';
import '../model/desvio_detail.dart';
import 'tratativa_item_card.dart';

/// Tratativas do plano atual, ainda não submetido (rodada == null).
/// Espelha a seção "Tratativas do Novo Plano" do web, exibida acima do
/// histórico de planos já submetidos.
class TratativasPendentesSection extends StatelessWidget {
  final DesvioDetail d;
  final String? token;

  const TratativasPendentesSection({super.key, required this.d, required this.token});

  @override
  Widget build(BuildContext context) {
    final pendentes = d.tratativas.where((t) => t.rodada == null).toList();
    if (pendentes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRATATIVAS DO PLANO ATUAL (${pendentes.length})',
          style: const TextStyle(
              color: ProtoColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: .5),
        ),
        const SizedBox(height: 8),
        for (final t in pendentes) TratativaItemCard(tratativa: t, token: token),
        const SizedBox(height: 8),
      ],
    );
  }
}
