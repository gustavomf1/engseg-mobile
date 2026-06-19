import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:engseg_mobile/core/notifications/fcm_service.dart';

void main() {
  late GlobalKey<NavigatorState> navigatorKey;
  late GoRouter router;
  late FcmService service;

  setUp(() {
    navigatorKey = GlobalKey<NavigatorState>();
    router = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/oc/:id', builder: (_, state) => Text('NC ${state.pathParameters['id']}')),
      ],
    );
    service = FcmService(
      bffDio: Dio(),
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
      navigatorKey: navigatorKey,
      onNotificationReceived: () {},
    );
  });

  testWidgets('navigateToNc navega para /oc/{ncId} quando data tem ncId', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    service.navigateToNc(RemoteMessage(data: {'ncId': 'nc-123'}));
    await tester.pumpAndSettle();

    expect(find.text('NC nc-123'), findsOneWidget);
  });

  testWidgets('navigateToNc nao navega quando data nao tem ncId', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    service.navigateToNc(RemoteMessage(data: const {}));
    await tester.pumpAndSettle();

    expect(find.text('NC nc-123'), findsNothing);
  });
}
