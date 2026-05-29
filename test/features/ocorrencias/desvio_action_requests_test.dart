import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/features/ocorrencias/model/desvio_action_requests.dart';

void main() {
  test('AdicionarTrativaRequest serializa corretamente', () {
    final j = const AdicionarTrativaRequest(
      titulo: 'T',
      descricao: 'D',
      evidenciaIds: ['e1', 'e2'],
    ).toJson();
    expect(j['titulo'], 'T');
    expect(j['evidenciaIds'], ['e1', 'e2']);
  });

  test('ReprovarTrativasDesvioRequest serializa itens', () {
    final j = const ReprovarTrativasDesvioRequest(
      itens: [ItemReprovacao(trativaId: 't1', motivo: 'm')],
      emailsManuais: ['a@b.com'],
    ).toJson();
    expect((j['itens'] as List).first['trativaId'], 't1');
    expect((j['itens'] as List).first['motivo'], 'm');
    expect(j['emailsManuais'], ['a@b.com']);
  });

  test('AprovarDesvioRequest omite comentario nulo', () {
    final j = const AprovarDesvioRequest(emailsManuais: []).toJson();
    expect(j.containsKey('comentario'), false);
    expect(j['emailsManuais'], []);
  });
}
