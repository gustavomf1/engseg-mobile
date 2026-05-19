import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/prototype_ui.dart';
import 'provider/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with SingleTickerProviderStateMixin {
  final email = TextEditingController(text: 'gustavo.ferreira@ers.eng.br');
  final password = TextEditingController(text: '••••••••••');
  bool loading = false;
  bool remember = true;

  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => loading = true);
    _spinController.repeat();
    try {
      await ref.read(authProvider.notifier).login(
        email.text.trim(),
        password.text,
      );
      if (!mounted) return;
      final session = ref.read(authProvider).value;
      if (session != null) {
        context.go('/workspace');
      }
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      _spinController.stop();
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProtoColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 22),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(offset: Offset(0, 18 * (1 - value)), child: child),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ProtoStatusBar(),
                  const SizedBox(height: 18),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: .86, end: 1),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [ProtoColors.blue, ProtoColors.purple]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('Bem-vindo', style: TextStyle(color: ProtoColors.text, fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text(
                    'Entre para registrar ocorrencias e acompanhar tratativas em campo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ProtoColors.muted, fontSize: 12, height: 1.45),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ProtoColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ProtoColors.border),
                    ),
                    child: Column(
                      children: [
                        _LoginInput(controller: email, icon: Icons.mail_rounded, hint: 'seu@email.com.br', keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 10),
                        _LoginInput(controller: password, icon: Icons.lock_rounded, hint: 'Senha', obscure: true, trailing: Icons.visibility_rounded),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => setState(() => remember = !remember),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: remember ? ProtoColors.blue : Colors.transparent,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(color: remember ? ProtoColors.blue : ProtoColors.borderStrong),
                                      ),
                                      child: remember ? const Icon(Icons.check_rounded, color: Colors.white, size: 13) : null,
                                    ),
                                    const SizedBox(width: 8),
                                    const Flexible(
                                      child: Text(
                                        'Manter conectado',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: ProtoColors.muted, fontSize: 11, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                              child: const Text('Esqueci a senha', style: TextStyle(color: ProtoColors.blue, fontSize: 11, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: ProtoColors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: loading ? null : _submit,
                            icon: loading
                                ? RotationTransition(
                                    turns: _spinController,
                                    child: const Icon(Icons.sync_rounded, size: 18),
                                  )
                                : const Icon(Icons.arrow_forward_rounded, size: 18),
                            label: Text(loading ? 'Entrando...' : 'Entrar', style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text('v1.0.0 · build 2026.05.06', style: TextStyle(color: ProtoColors.muted2, fontSize: 10, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('EngSeg / SGS · ERS Engenharia', style: TextStyle(color: ProtoColors.muted2, fontSize: 10, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginInput extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final IconData? trailing;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;

  const _LoginInput({
    required this.controller,
    required this.icon,
    required this.hint,
    this.trailing,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: ProtoColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ProtoColors.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: ProtoColors.text, fontSize: 12, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          hintText: hint,
          prefixIcon: Icon(icon, size: 16, color: ProtoColors.muted),
          suffixIcon: trailing == null ? null : Icon(trailing, size: 16, color: ProtoColors.muted),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
