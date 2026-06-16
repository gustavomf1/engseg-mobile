import 'package:flutter/material.dart';

class EngSegColors extends ThemeExtension<EngSegColors> {
  final Color bgBase;
  final Color bgSurface;
  final Color bgElevated;
  final Color bgMuted;
  final Color borderSoft;
  final Color borderMain;
  final Color fg0;
  final Color fg1;
  final Color fg2;
  final Color fg3;
  final Color accent;
  final Color accentHover;
  final Color statusGreenBg, statusGreenFg;
  final Color statusYellowBg, statusYellowFg;
  final Color statusRedBg, statusRedFg;
  final Color statusBlueBg, statusBlueFg;
  final Color statusIndigoBg, statusIndigoFg;
  final Color statusPurpleBg, statusPurpleFg;
  final Color statusOrangeBg, statusOrangeFg;
  final Color sevBaixo;
  final Color sevMedio;
  final Color sevAlto;
  final Color sevCritico;

  const EngSegColors({
    required this.bgBase,
    required this.bgSurface,
    required this.bgElevated,
    required this.bgMuted,
    required this.borderSoft,
    required this.borderMain,
    required this.fg0,
    required this.fg1,
    required this.fg2,
    required this.fg3,
    required this.accent,
    required this.accentHover,
    required this.statusGreenBg,
    required this.statusGreenFg,
    required this.statusYellowBg,
    required this.statusYellowFg,
    required this.statusRedBg,
    required this.statusRedFg,
    required this.statusBlueBg,
    required this.statusBlueFg,
    required this.statusIndigoBg,
    required this.statusIndigoFg,
    required this.statusPurpleBg,
    required this.statusPurpleFg,
    required this.statusOrangeBg,
    required this.statusOrangeFg,
    required this.sevBaixo,
    required this.sevMedio,
    required this.sevAlto,
    required this.sevCritico,
  });

  static const light = EngSegColors(
    bgBase: Color(0xFFF1F5F9),
    bgSurface: Color(0xFFFFFFFF),
    bgElevated: Color(0xFFF8FAFC),
    bgMuted: Color(0xFFF1F5F9),
    borderSoft: Color(0xFFE2E8F0),
    borderMain: Color(0xFFCBD5E1),
    fg0: Color(0xFF0F172A),
    fg1: Color(0xFF1E293B),
    fg2: Color(0xFF475569),
    fg3: Color(0xFF94A3B8),
    accent: Color(0xFF3B82F6),
    accentHover: Color(0xFF2563EB),
    statusGreenBg: Color(0xFFD1FAE5),
    statusGreenFg: Color(0xFF15803D),
    statusYellowBg: Color(0xFFFEF3C7),
    statusYellowFg: Color(0xFFA16207),
    statusRedBg: Color(0xFFFEE2E2),
    statusRedFg: Color(0xFFB91C1C),
    statusBlueBg: Color(0xFFDBEAFE),
    statusBlueFg: Color(0xFF1D4ED8),
    statusIndigoBg: Color(0xFFE0E7FF),
    statusIndigoFg: Color(0xFF4338CA),
    statusPurpleBg: Color(0xFFF3E8FF),
    statusPurpleFg: Color(0xFF7E22CE),
    statusOrangeBg: Color(0xFFFFEDD5),
    statusOrangeFg: Color(0xFFC2410C),
    sevBaixo: Color(0xFF3FB950),
    sevMedio: Color(0xFFD29922),
    sevAlto: Color(0xFFF97316),
    sevCritico: Color(0xFFF85149),
  );

  static const dark = EngSegColors(
    bgBase: Color(0xFF0B1118),        // ProtoColors.bg
    bgSurface: Color(0xFF151A21),     // ProtoColors.surface
    bgElevated: Color(0xFF1A2028),    // ProtoColors.surface2
    bgMuted: Color(0xFF1A2534),       // ProtoColors.hero
    borderSoft: Color(0xFF26303B),    // ProtoColors.border
    borderMain: Color(0xFF748195),    // ProtoColors.borderStrong
    fg0: Color(0xFFF8FBFF),           // ProtoColors.text
    fg1: Color(0xFFBCC5D0),
    fg2: Color(0xFF566170),           // ProtoColors.muted
    fg3: Color(0xFF3F4A57),           // ProtoColors.muted2
    accent: Color(0xFF58A6FF),        // ProtoColors.blue
    accentHover: Color(0xFF88BFFF),
    statusGreenBg: Color(0xFF0B3A1C),
    statusGreenFg: Color(0xFF3FB950), // ProtoColors.green
    statusYellowBg: Color(0xFF4A390A),
    statusYellowFg: Color(0xFFD29922), // ProtoColors.yellow
    statusRedBg: Color(0xFF4A1017),
    statusRedFg: Color(0xFFFF4D4D),   // ProtoColors.red
    statusBlueBg: Color(0xFF0B2A3A),
    statusBlueFg: Color(0xFF58A6FF),
    statusIndigoBg: Color(0xFF2A164A),
    statusIndigoFg: Color(0xFF5F3FF2), // ProtoColors.purple
    statusPurpleBg: Color(0xFF1F1040),
    statusPurpleFg: Color(0xFF5F3FF2),
    statusOrangeBg: Color(0xFF2B1800),
    statusOrangeFg: Color(0xFFFF7A1A), // ProtoColors.orange
    sevBaixo: Color(0xFF3FB950),
    sevMedio: Color(0xFFD29922),
    sevAlto: Color(0xFFF97316),
    sevCritico: Color(0xFFFF4D4D),
  );

  @override
  EngSegColors copyWith() => this;

  @override
  EngSegColors lerp(ThemeExtension<EngSegColors>? other, double t) =>
      t < .5 ? this : other as EngSegColors;
}

class EngSegRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

class EngSegShadows {
  static const sm = [
    BoxShadow(color: Color(0x12000000), offset: Offset(0, 1), blurRadius: 3),
  ];
  static const md = [
    BoxShadow(color: Color(0x12000000), offset: Offset(0, 4), blurRadius: 8),
  ];
  static const lg = [
    BoxShadow(color: Color(0x33000000), offset: Offset(0, 10), blurRadius: 30),
  ];
}

extension EngSegTheme on BuildContext {
  EngSegColors get c => Theme.of(this).extension<EngSegColors>()!;
}

ThemeData engSegThemeLight() => _theme(EngSegColors.light, Brightness.light);
ThemeData engSegThemeDark() => _theme(EngSegColors.dark, Brightness.dark);

class EngSegMotion {
  static const fast = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 240);
  static const standard = Duration(milliseconds: 300);
  static const curve = Curves.easeOutCubic;
}

ThemeData _theme(EngSegColors c, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.bgBase,
    fontFamily: 'Manrope',
    colorScheme: isDark
        ? ColorScheme.dark(
            primary: c.fg0,
            onPrimary: c.bgBase,
            secondary: c.accent,
            surface: c.bgSurface,
            onSurface: c.fg0,
            error: c.statusRedFg,
          )
        : ColorScheme.light(
            primary: c.fg0,
            onPrimary: Colors.white,
            secondary: c.accent,
            surface: c.bgSurface,
            onSurface: c.fg0,
            error: c.statusRedFg,
          ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.bgSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EngSegRadius.sm),
        borderSide: BorderSide(color: c.borderSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EngSegRadius.sm),
        borderSide: BorderSide(color: c.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EngSegRadius.sm),
        borderSide: BorderSide(color: c.accent, width: 1.6),
      ),
    ),
    extensions: [c],
  );
}
