import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/prototype_ui.dart';
import 'provider/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1200), _checkSession);
  }

  Future<void> _checkSession() async {
    if (!mounted) return;
    final session = await ref.read(authProvider.future);
    if (!mounted) return;
    if (session == null) {
      context.go('/login');
    } else {
      final workspace = ref.read(workspaceProvider);
      context.go(workspace == null ? '/workspace' : '/feed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProtoColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.fromLTRB(16, 6, 16, 0), child: ProtoStatusBar()),
            Expanded(
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: .82, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutBack,
                  builder: (_, scale, child) => Opacity(opacity: scale.clamp(0, 1), child: Transform.scale(scale: scale, child: child)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ProtoColors.blue.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: ProtoColors.blue.withValues(alpha: .35), width: 2),
                        ),
                        child: Container(
                          decoration: BoxDecoration(gradient: const LinearGradient(colors: [ProtoColors.blue, ProtoColors.purple]), borderRadius: BorderRadius.circular(18)),
                          child: const Icon(Icons.shield_outlined, color: Colors.white, size: 42),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('EngSeg', style: TextStyle(color: ProtoColors.text, fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      const Text('SISTEMA DE GESTAO DE SEGURANCA', style: TextStyle(color: ProtoColors.muted, fontSize: 10, letterSpacing: .8, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 28),
                      Container(width: 58, height: 2, decoration: const BoxDecoration(gradient: LinearGradient(colors: [ProtoColors.muted2, ProtoColors.blue, ProtoColors.muted2]))),
                    ],
                  ),
                ),
              ),
            ),
            Container(width: 100, height: 4, margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(99))),
          ],
        ),
      ),
    );
  }
}
