import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/shared/widgets/status_color_helper.dart';
import 'package:engseg_mobile/shared/theme/tokens.dart';

void main() {
  group('StatusColorHelper.nc', () {
    test('vencida retorna bg vermelho escuro', () {
      final c = StatusColorHelper.ncColors('ABERTA', vencida: true);
      expect(c.bg, const Color(0xFF4A1017));
      expect(c.fg, EngSegColors.dark.statusRedFg);
    });
    test('CONCLUIDA retorna verde', () {
      final c = StatusColorHelper.ncColors('CONCLUIDA', vencida: false);
      expect(c.bg, EngSegColors.dark.statusGreenBg);
      expect(c.fg, EngSegColors.dark.statusGreenFg);
    });
    test('EM_EXECUCAO retorna índigo', () {
      final c = StatusColorHelper.ncColors('EM_EXECUCAO', vencida: false);
      expect(c.bg, EngSegColors.dark.statusIndigoBg);
    });
    test('ABERTA default retorna amarelo', () {
      final c = StatusColorHelper.ncColors('ABERTA', vencida: false);
      expect(c.bg, EngSegColors.dark.statusYellowBg);
    });
  });

  group('StatusColorHelper.desvio', () {
    test('CONCLUIDO retorna verde', () {
      final c = StatusColorHelper.desvioColors('CONCLUIDO');
      expect(c.fg, EngSegColors.dark.statusGreenFg);
    });
    test('EM_ANALISE retorna amarelo', () {
      final c = StatusColorHelper.desvioColors('EM_ANALISE');
      expect(c.bg, EngSegColors.dark.statusYellowBg);
    });
  });

  group('StatusColorHelper labels', () {
    test('ncLabel ABERTA', () => expect(StatusColorHelper.ncLabel('ABERTA'), 'Aberta'));
    test('desvioLabel CONCLUIDO', () => expect(StatusColorHelper.desvioLabel('CONCLUIDO'), 'Concluído'));
  });
}
