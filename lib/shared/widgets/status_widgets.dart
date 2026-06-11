import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class StatusPill extends StatelessWidget {
  final String label;
  final String tone;
  final IconData? icon;
  final bool mini;

  const StatusPill({super.key, required this.label, this.tone = 'blue', this.icon, this.mini = false});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(context.c, tone);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: mini ? 8 : 10, vertical: mini ? 3 : 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(EngSegRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: mini ? 10 : 13, color: fg),
            const SizedBox(width: 4),
          ],
          if (label.isNotEmpty) Text(label, style: TextStyle(color: fg, fontSize: mini ? 11 : 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class MobileBadge extends StatelessWidget {
  const MobileBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const StatusPill(label: 'Mobile', tone: 'blue', icon: Icons.smartphone_rounded);
  }
}

class SeverityDot extends StatelessWidget {
  final String severity;
  final double size;

  const SeverityDot({super.key, required this.severity, this.size = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: severityColor(context, severity),
        shape: BoxShape.circle,
        border: Border.all(color: context.c.bgSurface, width: size > 10 ? 2 : 0),
      ),
    );
  }
}

Color severityColor(BuildContext context, String severity) {
  final c = context.c;
  return switch (severity) {
    'baixo' => c.sevBaixo,
    'medio' => c.sevMedio,
    'alto' => c.sevAlto,
    'critico' => c.sevCritico,
    _ => c.fg3,
  };
}

(Color, Color) _colors(EngSegColors c, String tone) {
  return switch (tone) {
    'green' => (c.statusGreenBg, c.statusGreenFg),
    'yellow' => (c.statusYellowBg, c.statusYellowFg),
    'red' => (c.statusRedBg, c.statusRedFg),
    'indigo' => (c.statusIndigoBg, c.statusIndigoFg),
    'purple' => (c.statusPurpleBg, c.statusPurpleFg),
    'orange' => (c.statusOrangeBg, c.statusOrangeFg),
    _ => (c.statusBlueBg, c.statusBlueFg),
  };
}

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SectionCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.c.bgSurface,
        borderRadius: BorderRadius.circular(EngSegRadius.md),
        border: Border.all(color: context.c.borderSoft),
        boxShadow: EngSegShadows.sm,
      ),
      child: child,
    );
  }
}
