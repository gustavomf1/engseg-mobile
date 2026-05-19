import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FcmService {
  final Dio bffDio;
  final GlobalKey<ScaffoldMessengerState> messengerKey;

  FcmService({required this.bffDio, required this.messengerKey});

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
    });
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
          onPressed: () {},
        ),
      ),
    );
  }
}
