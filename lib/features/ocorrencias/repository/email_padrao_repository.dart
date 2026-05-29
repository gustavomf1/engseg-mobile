import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/email_padrao.dart';
import '../../../core/network/dio_client.dart';

typedef EmailPadraoKey = ({String estabelecimentoId, String empresaId});

/// Emails de notificação padrão para um estabelecimento+empresa.
/// Retorna [] em caso de erro para o editor ainda funcionar com emails manuais.
final emailsPadraoProvider =
    FutureProvider.family<List<EmailPadrao>, EmailPadraoKey>((ref, key) async {
  final dio = ref.watch(dioProvider);
  try {
    final r = await dio.get<List<dynamic>>(
      '/api/emails-padrao',
      queryParameters: {
        'estabelecimentoId': key.estabelecimentoId,
        'empresaId': key.empresaId,
      },
    );
    return (r.data ?? [])
        .map((e) => EmailPadrao.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});
