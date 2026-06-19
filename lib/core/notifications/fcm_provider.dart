import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'fcm_service.dart';
import '../network/dio_client.dart';
import '../router/navigator_key.dart';
import '../../features/notifications/repository/notificacao_repository_impl.dart';
import '../../main.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  // bffDio com Bearer + refresh-on-401 (C3 exige JWT; M2 usa token curto).
  final bffDio = ref.watch(bffDioProvider);
  return FcmService(
    bffDio: bffDio,
    messengerKey: scaffoldMessengerKey,
    navigatorKey: navigatorKey,
    onNotificationReceived: () => ref.invalidate(notificacoesProvider),
  );
});
