import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/features/ocorrencias/model/email_padrao.dart';

void main() {
  test('EmailPadrao parseia corretamente', () {
    final e = EmailPadrao.fromJson({
      'id': 'p-1',
      'email': 'a@b.com',
      'descricao': 'Gestor',
      'empresaId': 'emp-1',
    });
    expect(e.id, 'p-1');
    expect(e.email, 'a@b.com');
    expect(e.descricao, 'Gestor');
  });
}
