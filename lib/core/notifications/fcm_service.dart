import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FcmService {
  final Dio bffDio;
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final GlobalKey<NavigatorState> navigatorKey;
  final VoidCallback onNotificationReceived;

  FcmService({
    required this.bffDio,
    required this.messengerKey,
    required this.navigatorKey,
    required this.onNotificationReceived,
  });

  Future<void> init(String usuarioId) async {
    await FirebaseMessaging.instance.requestPermission();

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _registerToken(usuarioId, token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _registerToken(usuarioId, newToken);
    });

    FirebaseMessaging.onMessage.listen((message) {
      _showForegroundBanner(message);
      onNotificationReceived();
    });

    // App em background, usuário tocou na notificação do sistema: Navigator já está montado.
    FirebaseMessaging.onMessageOpenedApp.listen(navigateToNc);

    // App estava fechado, foi aberto pelo toque: init() pode rodar antes do primeiro
    // frame do MaterialApp.router, então navigatorKey.currentState ainda seria null
    // aqui — adia para depois do próximo frame, quando o Navigator já está montado.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => navigateToNc(initialMessage));
    }
  }

  @visibleForTesting
  void navigateToNc(RemoteMessage message) {
    final ncId = message.data['ncId'];
    if (ncId == null) return;
    final context = navigatorKey.currentState?.context;
    if (context == null) return;
    context.push('/oc/$ncId');
  }

  Future<void> _registerToken(String usuarioId, String token) async {
    try {
      await bffDio.post<void>(
        '/devices/token',
        data: {
          'usuarioId': usuarioId,
          'fcmToken': token,
          'plataforma': 'ANDROID',
        },
      );
    } catch (_) {
      // non-fatal
    }
  }

  void _showForegroundBanner(RemoteMessage message) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message.notification?.title ?? 'Nova notificação',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A2534),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Ver',
          textColor: const Color(0xFF58A6FF),
          onPressed: () => navigateToNc(message),
        ),
      ),
    );
  }
}
