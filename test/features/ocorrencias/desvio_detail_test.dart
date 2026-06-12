import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/features/ocorrencias/model/desvio_detail.dart';
import 'package:engseg_mobile/features/ocorrencias/model/trativa_desvio.dart';

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

  test('rodadaAtual ignora tratativas pendentes ainda não submetidas (rodada null)', () {
    const d = DesvioDetail(
      id: 'd-3',
      titulo: 'X',
      status: 'AGUARDANDO_TRATATIVA',
      tratativas: [
        TrativaDesvio(
            id: 't-1', titulo: 'A', descricao: '', status: 'REPROVADO', numero: 1, rodada: 1),
        TrativaDesvio(
            id: 't-2', titulo: 'B', descricao: '', status: 'APROVADO', numero: 2, rodada: 2),
        TrativaDesvio(
            id: 't-3', titulo: 'C', descricao: '', status: 'PENDENTE', numero: 3, rodada: null),
      ],
    );
    expect(d.rodadaAtual, 2);
  });

  test('rodadaAtual é 0 quando só há tratativas pendentes não submetidas', () {
    const d = DesvioDetail(
      id: 'd-4',
      titulo: 'X',
      status: 'AGUARDANDO_TRATATIVA',
      tratativas: [
        TrativaDesvio(
            id: 't-1', titulo: 'A', descricao: '', status: 'PENDENTE', numero: 1, rodada: null),
      ],
    );
    expect(d.rodadaAtual, 0);
  });

  test('temTratativasPendentesNaoSubmetidas é true quando há tratativa com rodada null e status PENDENTE', () {
    const d = DesvioDetail(
      id: 'd-5',
      titulo: 'X',
      status: 'AGUARDANDO_TRATATIVA',
      tratativas: [
        TrativaDesvio(
            id: 't-1', titulo: 'A', descricao: '', status: 'REPROVADO', numero: 1, rodada: 1),
        TrativaDesvio(
            id: 't-2', titulo: 'B', descricao: '', status: 'PENDENTE', numero: 2, rodada: null),
      ],
    );
    expect(d.temTratativasPendentesNaoSubmetidas, isTrue);
  });

  test('temTratativasPendentesNaoSubmetidas é false quando não há tratativas com rodada null', () {
    const d = DesvioDetail(
      id: 'd-6',
      titulo: 'X',
      status: 'AGUARDANDO_TRATATIVA',
      tratativas: [
        TrativaDesvio(
            id: 't-1', titulo: 'A', descricao: '', status: 'REPROVADO', numero: 1, rodada: 1),
      ],
    );
    expect(d.temTratativasPendentesNaoSubmetidas, isFalse);
  });

  test('temTratativasPendentesNaoSubmetidas é false sem tratativas', () {
    const d = DesvioDetail(id: 'd-7', titulo: 'X', status: 'AGUARDANDO_TRATATIVA');
    expect(d.temTratativasPendentesNaoSubmetidas, isFalse);
  });
}
