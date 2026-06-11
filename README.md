# EngSeg Mobile

Aplicativo Flutter do EngSeg SGS para registro de Nao Conformidades e Desvios em campo.

## Estado atual

Esta base foi criada a partir do handoff de UI/UX em:

`/home/mag/Downloads/EngSeg SGS Design System/flutter_handoff`

Ela inclui:

- Tema claro/escuro com tokens EngSeg.
- Navegacao com `go_router`.
- Shell com bottom nav e FAB central.
- Telas mockadas: splash, login, feed, detalhe, notificacoes, dashboard, rascunhos, perfil, camera placeholder e wizard NC/Desvio.
- Dados mockados equivalentes ao pacote de handoff.

## Rodar localmente

Este workspace tem uma instalacao local do Flutter em `.tools/flutter`.

```bash
./.tools/flutter/bin/flutter run
```

Versoes instaladas:

- Flutter 3.41.9
- Dart 3.11.5

Comandos uteis:

```bash
./.tools/flutter/bin/flutter analyze
./.tools/flutter/bin/flutter test
./.tools/flutter/bin/flutter doctor
```

## Proximos passos tecnicos

1. Adicionar implementacoes reais de API em `lib/core/` com `dio` e interceptor JWT.
2. Trocar mocks por providers Riverpod.
3. Adicionar `drift`, `connectivity_plus`, `image_picker/geolocator` e `firebase_messaging`.
4. Implementar storage seguro do token e guards reais de autenticacao/perfil.
