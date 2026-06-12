import 'package:flutter/material.dart';

import '../../../shared/widgets/prototype_ui.dart';
import '../model/trativa_desvio.dart';

/// Card de uma [TrativaDesvio] individual: título, descrição, badge de status
/// (Pendente/Aprovada/Reprovada), motivo de reprovação (se houver) e miniaturas
/// das evidências anexadas.
class TratativaItemCard extends StatelessWidget {
  final TrativaDesvio tratativa;
  final String? token;

  const TratativaItemCard({super.key, required this.tratativa, this.token});

  @override
  Widget build(BuildContext context) {
    final t = tratativa;
    final (cardBg, cardBorder, pillFg, label) = switch (t.status) {
      'APROVADO' => (const Color(0xFF0B3A1C), ProtoColors.green, ProtoColors.green, 'Aprovada'),
      'REPROVADO' => (const Color(0xFF4A1017), ProtoColors.red, ProtoColors.red, 'Reprovada'),
      _ => (ProtoColors.surface2, ProtoColors.border, ProtoColors.blue, 'Pendente'),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ProtoCard(
        color: cardBg,
        border: Border.all(color: cardBorder),
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
              ProtoPill(label: label, bg: cardBg, fg: pillFg),
            ]),
            const SizedBox(height: 6),
            Text(t.descricao,
                style: const TextStyle(color: ProtoColors.muted, fontSize: 13)),
            if (t.motivoReprovacao != null && t.motivoReprovacao!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ProtoColors.red.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Motivo: ${t.motivoReprovacao}',
                    style: const TextStyle(
                        color: ProtoColors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
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
                                  headers: token != null
                                      ? {'Authorization': 'Bearer $token'}
                                      : {}),
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _thumbFallback(),
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
    );
  }

  Widget _thumbFallback() => Container(
        width: 64,
        height: 64,
        color: ProtoColors.surface2,
        child: const Icon(Icons.image_outlined, color: ProtoColors.muted),
      );
}
