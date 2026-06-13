# Esconder criação de NC/Desvio para usuário EXTERNO (mobile)

## Contexto

No web, o usuário do tipo `EXTERNO` já não tem acesso ao fluxo de criação de NC/Desvio
(ver memória `project_externo_permissions.md`). No mobile, porém, o botão flutuante (FAB)
"+" presente em `EngSegShell` está disponível para todos os perfis e abre um bottom sheet
com as opções "NC" e "Desvio", navegando para `/camera?tipo=...` e depois para
`/wizard/:tipo`.

O usuário EXTERNO não deve ter acesso a essa funcionalidade — nem visualmente (o botão não
deve aparecer) nem via navegação direta às rotas de criação.

## Ponto de entrada único

Levantamento confirmou que `/camera` e `/wizard/:tipo` só são alcançáveis hoje através do
FAB em `lib/shared/widgets/engseg_shell.dart`. Não há outros botões "+"/criar em
`drafts_page.dart`, `feed_page.dart` ou `desvio_feed_page.dart`.

## Mudanças

### 1. Esconder o FAB para EXTERNO (`lib/shared/widgets/engseg_shell.dart`)

- Converter `EngSegShell` de `StatelessWidget` para `ConsumerWidget` (padrão já usado em
  `feed_page.dart` e `desvio_feed_page.dart`: `ref.watch(authProvider).valueOrNull?.perfil == 'EXTERNO'`).
- Quando `isExterno == true`:
  - `floatingActionButton` retorna `null`.
  - `floatingActionButtonLocation` retorna `null`.
- O método `_showChooseTipo` e os widgets `_TipoCard` permanecem no código, apenas
  inacessíveis para EXTERNO.
- Nenhuma outra mudança no layout (bottom nav permanece igual para todos os perfis).

### 2. Bloquear rotas `/camera` e `/wizard/:tipo` para EXTERNO (`lib/core/router/app_router.dart`)

- No `redirect` do `GoRouter`, adicionar verificação: se `perfil == 'EXTERNO'` e
  (`state.matchedLocation == '/camera'` ou `state.matchedLocation.startsWith('/wizard')`),
  redirecionar para `/feed`.
- Cobre deep links, estado salvo de navegação ou qualquer tentativa de acesso direto.
- Não afeta o fluxo normal do EXTERNO (preenchimento de plano de ação em NC, que usa a
  rota `/oc/:id`, não `/wizard`).

## Fora do escopo

- Nenhuma mudança no backend ou na web — a permissão de criação já é controlada lá.
- Nenhuma mudança nos modelos de dados ou repositórios.
