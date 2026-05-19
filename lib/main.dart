import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/connectivity_provider.dart';
import 'core/router/app_router.dart';
import 'core/sync/sync_service.dart';
import 'core/sync/sync_status.dart';
import 'features/auth/provider/auth_provider.dart';
import 'shared/theme/tokens.dart';

void main() {
  runApp(const ProviderScope(child: EngSegApp()));
}

class EngSegApp extends ConsumerWidget {
  const EngSegApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return _AppConnectivityListener(
      child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'EngSeg',
      theme: engSegThemeLight(),
      darkTheme: engSegThemeDark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      builder: (context, child) => _MobileViewport(child: child ?? const SizedBox.shrink()),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
    ),
    );
  }
}

class _AppConnectivityListener extends ConsumerWidget {
  final Widget child;
  const _AppConnectivityListener({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<bool>>(connectivityProvider, (_, next) async {
      final isOnline = next.valueOrNull ?? false;
      if (!isOnline) return;

      final session = ref.read(authProvider).valueOrNull;
      if (session == null) return;

      ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
      try {
        await ref.read(syncServiceProvider).syncPendentes(token: session.token);
        ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
      } catch (_) {
        ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
      }
    });
    return child;
  }
}

class _MobileViewport extends StatelessWidget {
  final Widget child;

  const _MobileViewport({required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 520) return child;

    final colors = Theme.of(context).extension<EngSegColors>()!;
    return ColoredBox(
      color: colors.bgBase,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ClipRect(child: child),
        ),
      ),
    );
  }
}
