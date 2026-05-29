import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/features/ocorrencias/model/criar_nc_request.dart';
import 'package:engseg_mobile/features/ocorrencias/model/criar_desvio_request.dart';

void main() {
  test('CriarNcRequest serializa novos campos opcionais quando presentes', () {
    final json = const CriarNcRequest(
      estabelecimentoId: 'est-1',
      titulo: 'T',
      descricao: 'D',
      severidade: 3,
      probabilidade: 2,
      localizacaoId: 'loc-1',
      responsavelNcId: 'u-nc',
      responsavelTrativaId: 'u-tr',
      normaIds: ['n1'],
    ).toJson();
    expect(json['localizacaoId'], 'loc-1');
    expect(json['responsavelNcId'], 'u-nc');
    expect(json['responsavelTrativaId'], 'u-tr');
    expect(json['severidade'], 3);
  });

  test('CriarNcRequest omite opcionais nulos', () {
    final json = const CriarNcRequest(
      estabelecimentoId: 'est-1',
      titulo: 'T',
      descricao: 'D',
      severidade: 1,
      probabilidade: 1,
    ).toJson();
    expect(json.containsKey('localizacaoId'), false);
    expect(json.containsKey('responsavelNcId'), false);
  });

  test('CriarDesvioRequest serializa localizacaoId quando presente', () {
    final json = const CriarDesvioRequest(
      estabelecimentoId: 'est-1',
      titulo: 'T',
      localizacaoId: 'loc-9',
    ).toJson();
    expect(json['localizacaoId'], 'loc-9');
  });
}
