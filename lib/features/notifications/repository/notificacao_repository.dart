import '../model/notificacao_item.dart';

abstract class NotificacaoRepository {
  Future<List<NotificacaoItem>> listar({int page = 0, int size = 20});
  Future<void> marcarComoLida(String id);
}
