import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/features/ocorrencias/model/desvio_detail.dart';

void main() {
  test('DesvioDetail parseia resposta com tratativas e responsaveis', () {
    final d = DesvioDetail.fromJson({
      'id': 'd-1',
      'estabelecimentoId': 'est-1',
      'estabelecimentoNome': 'Refinaria',
      'titulo': 'EPI inadequado',
      'localizacaoNome': 'Bloco C',
      'descricao': 'desc',
      'dataRegistro': '2026-05-28T10:00:00',
      'orientacaoRealizada': 'orientado',
      'regraDeOuro': true,
      'status': 'AGUARDANDO_APROVACAO',
      'responsavelDesvioId': 'u-d',
      'responsavelDesvioNome': 'Eng A',
      'responsavelTratativaId': 'u-t',
      'responsavelTrivaNome': 'Tec B',
      'tratativas': [
        {
          'id': 't-1',
          'titulo': 'Troca de luva',
          'descricao': 'feito',
          'status': 'PENDENTE',
          'motivoReprovacao': null,
          'numero': 1,
          'rodada': 1,
          'dtCriacao': '2026-05-28T11:00:00',
          'evidencias': [
            {'id': 'e-1', 'nome': 'foto.jpg', 'url': 'http://x/e-1'},
          ],
        }
      ],
      'historico': [],
    });
    expect(d.id, 'd-1');
    expect(d.status, 'AGUARDANDO_APROVACAO');
    expect(d.responsavelDesvioId, 'u-d');
    expect(d.responsavelTratativaId, 'u-t');
    expect(d.responsavelTratativaNome, 'Tec B');
    expect(d.tratativas.length, 1);
    expect(d.tratativas.first.status, 'PENDENTE');
    expect(d.tratativas.first.rodada, 1);
    expect(d.tratativas.first.evidencias.first.url, 'http://x/e-1');
  });

  test('DesvioDetail tolera listas ausentes', () {
    final d = DesvioDetail.fromJson({
      'id': 'd-2',
      'titulo': 'X',
      'status': 'ABERTO',
    });
    expect(d.tratativas, isEmpty);
    expect(d.historico, isEmpty);
    expect(d.estabelecimentoNome, '');
  });
}
