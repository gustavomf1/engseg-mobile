import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import 'fcm_service.dart';
import '../../main.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  final bffDio = Dio(BaseOptions(baseUrl: AppConfig.bffBaseUrl));
  return FcmService(bffDio: bffDio, messengerKey: scaffoldMessengerKey);
});
