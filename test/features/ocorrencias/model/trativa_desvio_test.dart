import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/features/ocorrencias/model/trativa_desvio.dart';

Map<String, dynamic> _json({Object? rodada = 1}) => {
      'id': 't-1',
      'titulo': 'Tratativa',
      'descricao': 'Descrição',
      'status': 'PENDENTE',
      'numero': 1,
      'rodada': rodada,
    };

void main() {
  test('fromJson preserva rodada quando presente', () {
    final t = TrativaDesvio.fromJson(_json(rodada: 2));
    expect(t.rodada, 2);
  });

  test('fromJson mantém rodada null quando backend ainda não submeteu', () {
    final t = TrativaDesvio.fromJson(_json(rodada: null));
    expect(t.rodada, isNull);
  });

  test('fromJson mantém rodada null quando campo ausente', () {
    final json = _json()..remove('rodada');
    final t = TrativaDesvio.fromJson(json);
    expect(t.rodada, isNull);
  });
}
