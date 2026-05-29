import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_page.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../../features/auth/splash_page.dart';
import '../../features/auth/workspace_select_page.dart';
import '../../features/capture/camera_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/drafts/drafts_page.dart';
import '../../features/notifications/notif_page.dart';
import '../../features/ocorrencias/detail_page.dart';
import '../../features/ocorrencias/desvio_detail_page.dart';
import '../../features/ocorrencias/desvio_feed_page.dart';
import '../../features/ocorrencias/feed_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/wizard/wizard_page.dart';
import '../../shared/widgets/engseg_shell.dart';
import 'navigator_key.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.valueOrNull != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/';

      if (isSplash) return null;

      if (!isLoggedIn && !isLoggingIn) return '/login';

      if (isLoggedIn && isLoggingIn) return '/feed';

      final perfil = authState.valueOrNull?.perfil;
      if (state.matchedLocation == '/dashboard' && perfil != 'ENGENHEIRO') {
        return '/feed';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/workspace', builder: (_, __) => const WorkspaceSelectPage()),
      ShellRoute(
        builder: (_, __, child) => EngSegShell(child: child),
        routes: [
          GoRoute(path: '/feed', builder: (_, __) => const FeedPage()),
          GoRoute(path: '/desvios', builder: (_, __) => const DesvioFeedPage()),
          GoRoute(path: '/notif', builder: (_, __) => const NotifPage()),
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
        ],
      ),
      GoRoute(path: '/oc/:id', builder: (_, state) => DetailPage(id: state.pathParameters['id']!)),
      GoRoute(path: '/desvio/:id', builder: (_, state) => DesvioDetailPage(id: state.pathParameters['id']!)),
      GoRoute(path: '/drafts', builder: (_, __) => const DraftsPage()),
      GoRoute(
        path: '/camera',
        builder: (_, state) => CameraPage(tipo: state.uri.queryParameters['tipo'] ?? 'NC'),
      ),
      GoRoute(
        path: '/wizard/:tipo',
        builder: (_, state) => WizardPage(
          tipo: state.pathParameters['tipo'] ?? 'nc',
          extra: state.extra as Map<String, dynamic>?,
        ),
      ),
    ],
  );

  ref.listen(authProvider, (_, __) => router.refresh());

  return router;
});
