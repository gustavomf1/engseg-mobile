import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/features/ocorrencias/model/ocorrencia_summary.dart';

void main() {
  final ncJson = {
    'tipo': 'NAO_CONFORMIDADE',
    'id': 'nc-1',
    'titulo': 'NC Teste',
    'status': 'ABERTA',
    'nivelRisco': 'ALTO',
    'estabelecimentoNome': 'Obra Central',
    'dataRegistro': '2026-06-01',
    'dataLimiteResolucao': '2026-12-01',
    'vencida': false,
    'responsavelTratativaId': 'u1',
    'primeiraEvidenciaId': 'ev-1',
    'primeiraEvidenciaNome': 'foto.jpg',
  };

  final desvioJson = {
    'tipo': 'DESVIO',
    'id': 'dv-1',
    'titulo': 'Desvio Teste',
    'status': 'EM_ANALISE',
    'estabelecimentoNome': 'Canteiro B',
    'dataRegistro': '2026-06-05',
    'responsavelTratativaId': null,
    'primeiraEvidenciaId': null,
    'primeiraEvidenciaNome': null,
  };

  group('OcorrenciaSummary.fromJson', () {
    test('parseia NC com todos os campos', () {
      final nc = OcorrenciaSummary.fromJson(ncJson);
      expect(nc.tipo, 'NAO_CONFORMIDADE');
      expect(nc.id, 'nc-1');
      expect(nc.nivelRisco, 'ALTO');
      expect(nc.primeiraEvidenciaId, 'ev-1');
      expect(nc.primeiraEvidenciaNome, 'foto.jpg');
      expect(nc.vencida, false);
    });

    test('parseia Desvio com campos opcionais null', () {
      final dv = OcorrenciaSummary.fromJson(desvioJson);
      expect(dv.tipo, 'DESVIO');
      expect(dv.nivelRisco, isNull);
      expect(dv.primeiraEvidenciaId, isNull);
    });

    test('vencida=true quando dataLimiteResolucao no passado', () {
      final json = Map<String, dynamic>.from(ncJson)
        ..['dataLimiteResolucao'] = '2020-01-01'
        ..['status'] = 'ABERTA'
        ..['vencida'] = false;
      final nc = OcorrenciaSummary.fromJson(json);
      expect(nc.vencida, true);
    });

    test('vencida mantida false quando status CONCLUIDA', () {
      final json = Map<String, dynamic>.from(ncJson)
        ..['dataLimiteResolucao'] = '2020-01-01'
        ..['status'] = 'CONCLUIDA';
      final nc = OcorrenciaSummary.fromJson(json);
      expect(nc.vencida, false);
    });
  });

  group('OcorrenciaSummary helpers', () {
    test('isNc retorna true para NAO_CONFORMIDADE', () {
      expect(OcorrenciaSummary.fromJson(ncJson).isNc, true);
    });
    test('isDesvio retorna true para DESVIO', () {
      expect(OcorrenciaSummary.fromJson(desvioJson).isDesvio, true);
    });
    test('hasImageCover detecta extensão jpg', () {
      expect(OcorrenciaSummary.fromJson(ncJson).hasImageCover, true);
    });
    test('hasImageCover false para pdf', () {
      final json = Map<String, dynamic>.from(ncJson)
        ..['primeiraEvidenciaNome'] = 'laudo.pdf';
      expect(OcorrenciaSummary.fromJson(json).hasImageCover, false);
    });
    test('hasImageCover false quando sem evidência', () {
      expect(OcorrenciaSummary.fromJson(desvioJson).hasImageCover, false);
    });
  });
}
