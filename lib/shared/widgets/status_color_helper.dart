import 'package:flutter/material.dart';
import '../theme/tokens.dart';

typedef StatusColors = ({Color bg, Color fg});

class StatusColorHelper {
  static StatusColors ncColors(String status, {bool vencida = false}) {
    if (vencida) {
      return (bg: const Color(0xFF4A1017), fg: EngSegColors.dark.statusRedFg);
    }
    return switch (status) {
      'CONCLUIDA' || 'FECHADA' || 'APROVADA' => (
          bg: EngSegColors.dark.statusGreenBg,
          fg: EngSegColors.dark.statusGreenFg,
        ),
      'EM_EXECUCAO' => (
          bg: EngSegColors.dark.statusIndigoBg,
          fg: EngSegColors.dark.statusIndigoFg,
        ),
      'AGUARDANDO_TRATATIVA' => (
          bg: EngSegColors.dark.statusBlueBg,
          fg: EngSegColors.dark.statusBlueFg,
        ),
      _ => (
          bg: EngSegColors.dark.statusYellowBg,
          fg: EngSegColors.dark.statusYellowFg,
        ),
    };
  }

  static StatusColors desvioColors(String status) {
    return switch (status) {
      'CONCLUIDO' || 'FECHADO' || 'APROVADO' => (
          bg: EngSegColors.dark.statusGreenBg,
          fg: EngSegColors.dark.statusGreenFg,
        ),
      'EM_ANALISE' => (
          bg: EngSegColors.dark.statusYellowBg,
          fg: EngSegColors.dark.statusYellowFg,
        ),
      _ => (
          bg: EngSegColors.dark.bgMuted,
          fg: EngSegColors.dark.fg2,
        ),
    };
  }

  static String ncLabel(String status) => const {
        'ABERTA': 'Aberta',
        'EM_EXECUCAO': 'Em Execução',
        'AGUARDANDO_TRATATIVA': 'Aguardando',
        'CONCLUIDA': 'Concluída',
        'FECHADA': 'Fechada',
        'APROVADA': 'Aprovada',
        'REPROVADA': 'Reprovada',
      }[status] ??
      status;

  static String desvioLabel(String status) => const {
        'ABERTO': 'Aberto',
        'EM_ANALISE': 'Em Análise',
        'CONCLUIDO': 'Concluído',
        'FECHADO': 'Fechado',
      }[status] ??
      status;
}
