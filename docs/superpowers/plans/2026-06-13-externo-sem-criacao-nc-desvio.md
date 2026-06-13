# Esconder criação de NC/Desvio para usuário EXTERNO (mobile) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Usuários com `perfil == 'EXTERNO'` não devem ver o botão "+" de criar NC/Desvio no mobile, e tentativas de acessar diretamente `/camera` ou `/wizard/:tipo` devem ser redirecionadas para `/feed`.

**Architecture:** Duas mudanças independentes: (1) um helper puro `isExternoBlockedRoute` usado pelo `redirect` do `GoRouter` em `app_router.dart`, testado isoladamente; (2) `EngSegShell` passa a ser um `ConsumerWidget` que esconde o FAB quando o perfil logado é `EXTERNO`.

**Tech Stack:** Flutter, flutter_riverpod, go_router, flutter_test.

---

### Task 1: Helper `isExternoBlockedRoute` para o redirect do router

**Files:**
- Create: `lib/core/router/route_guards.dart`
- Test: `test/core/router/route_guards_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/core/router/route_guards.dart';

void main() {
  group('isExternoBlockedRoute', () {
    test('bloqueia acesso direto a /camera', () {
      expect(isExternoBlockedRoute('/camera'), isTrue);
    });

    test('bloqueia acesso direto a /wizard/:tipo', () {
      expect(isExternoBlockedRoute('/wizard/nc'), isTrue);
      expect(isExternoBlockedRoute('/wizard/desvio'), isTrue);
    });

    test('nao bloqueia rotas normais do feed', () {
      expect(isExternoBlockedRoute('/feed'), isFalse);
      expect(isExternoBlockedRoute('/desvios'), isFalse);
      expect(isExternoBlockedRoute('/profile'), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/router/route_guards_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'engseg_mobile' in 'package:engseg_mobile/core/router/route_guards.dart'` (arquivo `lib/core/router/route_guards.dart` ainda não existe)

- [ ] **Step 3: Write minimal implementation**

```dart
/// Rotas de criação de NC/Desvio que o perfil EXTERNO não pode acessar
/// diretamente (deep link, estado salvo de navegação, etc.).
bool isExternoBlockedRoute(String matchedLocation) {
  return matchedLocation == '/camera' || matchedLocation.startsWith('/wizard');
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/router/route_guards_test.dart`
Expected: PASS (3 testes)

- [ ] **Step 5: Commit**

```bash
git add lib/core/router/route_guards.dart test/core/router/route_guards_test.dart
git commit -m "feat: adiciona helper isExternoBlockedRoute para o router"
```

---

### Task 2: Bloquear /camera e /wizard/:tipo para EXTERNO no redirect do GoRouter

**Files:**
- Modify: `lib/core/router/app_router.dart`

- [ ] **Step 1: Adicionar o import do helper criado na Task 1**

Em `lib/core/router/app_router.dart`, adicionar junto aos demais imports (após a linha `import 'navigator_key.dart';`):

```dart
import 'route_guards.dart';
```

- [ ] **Step 2: Adicionar a verificação no redirect**

Em `lib/core/router/app_router.dart`, o bloco atual do `redirect` (linhas 42-47) é:

```dart
      final perfil = authState.valueOrNull?.perfil;
      if (state.matchedLocation == '/dashboard' && perfil != 'ENGENHEIRO') {
        return '/feed';
      }

      return null;
```

Substituir por:

```dart
      final perfil = authState.valueOrNull?.perfil;
      if (state.matchedLocation == '/dashboard' && perfil != 'ENGENHEIRO') {
        return '/feed';
      }

      if (perfil == 'EXTERNO' && isExternoBlockedRoute(state.matchedLocation)) {
        return '/feed';
      }

      return null;
```

- [ ] **Step 3: Rodar análise estática para confirmar que compila**

Run: `flutter analyze lib/core/router/app_router.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/core/router/app_router.dart
git commit -m "feat: bloqueia acesso direto de EXTERNO a /camera e /wizard"
```

---

### Task 3: Esconder o FAB de criação para o perfil EXTERNO no EngSegShell

**Files:**
- Modify: `lib/shared/widgets/engseg_shell.dart`
- Test: `test/shared/widgets/engseg_shell_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:engseg_mobile/features/auth/model/login_response.dart';
import 'package:engseg_mobile/features/auth/provider/auth_provider.dart';
import 'package:engseg_mobile/shared/widgets/engseg_shell.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._session);

  final LoginResponse? _session;

  @override
  Future<LoginResponse?> build() async => _session;
}

LoginResponse _session(String perfil) => LoginResponse(
      id: 'u1',
      token: 'tok',
      nome: 'Usuario Teste',
      email: 'teste@example.com',
      perfil: perfil,
      isAdmin: false,
    );

Widget _wrap(LoginResponse? session) {
  final router = GoRouter(
    initialLocation: '/feed',
    routes: [
      ShellRoute(
        builder: (_, __, child) => EngSegShell(child: child),
        routes: [
          GoRoute(path: '/feed', builder: (_, __) => const SizedBox()),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authProvider.overrideWith(() => _FakeAuthNotifier(session)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('mostra o FAB de criacao para perfil ENGENHEIRO', (tester) async {
    await tester.pumpWidget(_wrap(_session('ENGENHEIRO')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });

  testWidgets('mostra o FAB de criacao para perfil TECNICO', (tester) async {
    await tester.pumpWidget(_wrap(_session('TECNICO')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });

  testWidgets('esconde o FAB de criacao para perfil EXTERNO', (tester) async {
    await tester.pumpWidget(_wrap(_session('EXTERNO')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_rounded), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/shared/widgets/engseg_shell_test.dart`
Expected: FAIL no teste `esconde o FAB de criacao para perfil EXTERNO` — `find.byIcon(Icons.add_rounded)` encontra 1 widget (o FAB é exibido para todos os perfis hoje), mas o teste espera `findsNothing`.

- [ ] **Step 3: Write minimal implementation**

Em `lib/shared/widgets/engseg_shell.dart`, o arquivo começa com:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'prototype_ui.dart';
```

Adicionar duas novas linhas de import, resultando em:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/provider/auth_provider.dart';
import 'prototype_ui.dart';
```

Trocar a declaração da classe de:

```dart
class EngSegShell extends StatelessWidget {
  final Widget child;

  const EngSegShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
```

para:

```dart
class EngSegShell extends ConsumerWidget {
  final Widget child;

  const EngSegShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(authProvider).valueOrNull?.perfil;
    final isExterno = perfil == 'EXTERNO';
```

E trocar as propriedades `floatingActionButtonLocation` e `floatingActionButton` do `Scaffold` de:

```dart
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ProtoColors.purple,
          border: Border.all(color: ProtoColors.blue, width: 2),
          boxShadow: [BoxShadow(color: ProtoColors.blue.withValues(alpha: .35), blurRadius: 16, spreadRadius: 2)],
        ),
        child: IconButton(
          onPressed: () => _showChooseTipo(context),
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 31),
        ),
      ),
```

para:

```dart
      floatingActionButtonLocation: isExterno ? null : FloatingActionButtonLocation.centerDocked,
      floatingActionButton: isExterno
          ? null
          : Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ProtoColors.purple,
                border: Border.all(color: ProtoColors.blue, width: 2),
                boxShadow: [BoxShadow(color: ProtoColors.blue.withValues(alpha: .35), blurRadius: 16, spreadRadius: 2)],
              ),
              child: IconButton(
                onPressed: () => _showChooseTipo(context),
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 31),
              ),
            ),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/shared/widgets/engseg_shell_test.dart`
Expected: PASS (3 testes)

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/engseg_shell.dart test/shared/widgets/engseg_shell_test.dart
git commit -m "feat: esconde FAB de criacao de NC/Desvio para usuario EXTERNO"
```

---

### Task 4: Verificação final

**Files:** nenhum arquivo novo — apenas validação.

- [ ] **Step 1: Rodar toda a suíte de testes**

Run: `flutter test`
Expected: todos os testes passam, incluindo os 3 novos de `route_guards_test.dart` e os 3 novos de `engseg_shell_test.dart`.

- [ ] **Step 2: Rodar análise estática do projeto**

Run: `flutter analyze`
Expected: `No issues found!`
