# Spec #1 — Fundação de Design + Redesenho das Listagens (NC / Desvio)

**Data:** 2026-06-13
**Projeto:** engseg-mobile (Flutter)
**Status:** Aprovado para planejamento

---

## Contexto

O app mobile funciona, mas o visual está "simples". Diagnóstico do estado atual:

1. **Dois sistemas de cor paralelos.** Existe um tema completo em `lib/shared/theme/tokens.dart` (`EngSegColors`, com modo claro e escuro, fonte Manrope, tokens de raio/sombra), mas as telas reais usam `ProtoColors` de `lib/shared/widgets/prototype_ui.dart` — cores hardcoded, só escuro, herdadas do protótipo. O tema "oficial" não é usado.
2. **Sem preview de imagem nas listagens.** Os feeds de NC (`feed_page.dart`) e Desvio (`desvio_feed_page.dart`) mostram só um ícone genérico. Os modelos `NcSummary`/`DesvioSummary` nem têm campo de imagem.
3. **Quase nenhuma animação**, apesar do `flutter_animate` já estar no `pubspec.yaml`. Loading é `CircularProgressIndicator` cru.
4. **Sem cache de imagem.** As fotos do detalhe usam `NetworkImage(url, headers: {Authorization})` direto — rebaixadas da rede toda vez, sem placeholder nem fade-in.

### Descoberta-chave sobre os dados

A web já mostra foto na listagem unificada de Ocorrências. Investigação do backend (`engseg-api`):

- O endpoint **`GET /api/ocorrencias`** (`OcorrenciaController`) já devolve, por item, **`primeiraEvidenciaId`** e **`primeiraEvidenciaNome`** (via `putPrimeiraEvidencia`), além de **todos** os campos que os cards do mobile precisam — NC: `nivelRisco`, `severidade`, `probabilidade`, `estabelecimentoNome`, `dataLimiteResolucao`, `vencida`, `responsavelTratativaId`; Desvio: `status`, `estabelecimentoNome`, `dataRegistro`, `responsavelTratativaId`. Tem ainda o parâmetro `meuPapel`, que faz no servidor o mesmo filtro de EXTERNO que o app faz na mão hoje.
- O mobile **não usa** esse endpoint — usa `GET /api/nao-conformidades` e `GET /api/desvios`, mais "magros", que nunca receberam a lógica de thumbnail.

**Conclusão: nenhuma mudança de backend é necessária.** O mobile passa a consumir `/api/ocorrencias` e separa por `tipo`.

---

## Objetivos

- Estabelecer uma **fundação de design unificada** (tokens + kit de componentes + linguagem de movimento) reutilizável por todo o app.
- Redesenhar os **dois feeds (NC e Desvio)** com preview de foto, movimento sutil e carregamento com skeleton.
- Migrar os feeds para **`/api/ocorrencias`**, trazendo a foto de capa sem tocar no backend.
- Provar toda a linguagem visual/movimento nas telas de maior valor, deixando a base pronta para os specs seguintes.

## Não-objetivos (ficam para specs posteriores)

- Redesenho interno do `detail_page.dart` (4036 linhas), `wizard_page.dart` (3182), dashboard, perfil e login. **Spec #1 só toca no detalhe o mínimo necessário para o destino do hero.**
- Modo claro. **Mobile é sempre escuro** (decisão do usuário). A arquitetura de tokens fica pronta para um claro futuro, mas ele não é implementado.
- Qualquer alteração no `engseg-api`.

---

## Decisões (tomadas no brainstorming)

| Tema | Decisão |
|---|---|
| Estilo do card | **B — Foto de capa**: imagem 16:9 no topo do card, pills sobre a imagem, título em overlay |
| Origem da foto | **`/api/ocorrencias`** (já retorna `primeiraEvidenciaId/Nome`); zero mudança de backend |
| Escopo | App todo, **sequenciado em specs**; este é o #1 (fundação + listagens) |
| Tema | **Escuro unificado.** Fonte única de cor adotando os valores **atuais** do `ProtoColors` |
| Animações | **Sutil/profissional** — 150–300ms, sem "bounce" |
| Estratégia | **A** — token único + kit de widgets, migrando tela a tela; `ProtoColors` vira alias depreciado |

---

## Arquitetura

### 1. Fundação de tokens

- `EngSegColors.dark` passa a ser a **fonte única**, com os **valores atuais do `ProtoColors`** preservados exatamente (ex.: `bgBase #0B1118`, `bgSurface #151A21`, `border #26303B`, `accent/blue #58A6FF`, `red #FF4D4D`, `yellow #D29922`, `green #3FB950`, `orange #FF7A1A`). **Não** adotar os valores divergentes que já existiam no `tokens.dart` (ex.: `#0D1117`, `#F85149`) — isso mudaria o visual aprovado.
- Adicionar tokens de **duração/curva de animação** (ex.: `EngSegMotion.fast = 180ms`, `EngSegMotion.base = 240ms`, curva padrão `Curves.easeOutCubic`).
- `ProtoColors` é mantido como **alias depreciado** delegando aos tokens (`static const bg = EngSegColors.dark.bgBase` ou equivalente), para nada quebrar durante a migração incremental. Marcar com `@Deprecated`.

### 2. Kit de widgets compartilhados (`lib/shared/widgets/`)

- **`EngAuthImage`** — imagem de rede autenticada com cache em disco. Encapsula `cached_network_image` passando o header `Authorization: Bearer <token>`, com fade-in, placeholder (shimmer) e `errorBuilder` (ícone de imagem quebrada). Substitui os `NetworkImage(headers:)` espalhados (hoje em `detail_page.dart`). O token vem do `authProvider`.
- **`EngCoverCard`** — implementa o card B. Recebe: pills (tipo + status + flags), título, linha de meta, e os dados de evidência (`primeiraEvidenciaId`, `primeiraEvidenciaNome`, contagem opcional). **Lógica de capa por extensão** (mesma regra da web — `EvidenciaThumbnail.tsx`):
  - extensão de `primeiraEvidenciaNome` ∈ {jpg, jpeg, png, gif, webp} → renderiza a foto via `EngAuthImage` (capa 16:9 com degradê de baixo);
  - extensão fora disso (pdf, vídeo, etc.) → **fallback documento**: capa com degradê + ícone de arquivo + extensão;
  - sem evidência → **fallback neutro**: degradê + ícone temático (ex.: escudo para NC), preservando o layout do card.
  - Em todos os casos as pills e o título ficam legíveis sobre um scrim escuro.
- **`EngSkeleton`** — bloco com shimmer; e uma lista de skeletons no formato do `EngCoverCard` para o estado de loading dos feeds (substitui `CircularProgressIndicator`).
- **`EngPill`** — pill reutilizável (evolui o `ProtoPill`).
- **`StatusColors` helper** — centraliza o mapeamento status/severidade → (bg, fg), hoje duplicado como `_statusBg/_statusFg` nos dois feeds.
- **Helpers de movimento** (sobre `flutter_animate`):
  - `staggeredListEntrance` — fade + slide-up em cascata para itens de lista;
  - `TapScale` — wrapper que aplica scale ~0.97 ao toque com retorno suave;
  - transição de página padrão (fade-through) para o `go_router`.

### 3. Camada de dados

- Novo modelo/parsing unificado a partir de `/api/ocorrencias` (resposta é `List<Map<String,Object>>` com campo `tipo`).
- **`ocorrenciasProvider`** (Riverpod) chama `GET /api/ocorrencias`, passando `estabelecimentoId` (do `workspaceProvider`) e, para EXTERNO, `meuPapel=RESPONSAVEL_TRATATIVA_NC`/`RESPONSAVEL_TRATATIVA_DESVIO` conforme o feed — substituindo o filtro client-side atual.
- `NcSummary` e `DesvioSummary` ganham `primeiraEvidenciaId` e `primeiraEvidenciaNome` (opcionais). Os feeds derivam do provider unificado, filtrando por `tipo` (`NAO_CONFORMIDADE` / `DESVIO`).
- Os endpoints antigos (`/api/nao-conformidades`, `/api/desvios`) deixam de alimentar os feeds; só permanecem se usados em outro lugar (verificar no plano).

### 4. Os dois feeds redesenhados

- `feed_page.dart` (NC) e `desvio_feed_page.dart` (Desvio) reescritos sobre `EngCoverCard`, tokens e helpers de movimento:
  - estado de loading → lista de `EngSkeleton`;
  - dados → cascata de entrada (`staggeredListEntrance`);
  - cada card com `TapScale` e `Hero` na imagem de capa;
  - chips de filtro animados (já há `AnimatedContainer`; padronizar).
- Empty state e error state estilizados (hoje são texto cru).

### 5. Transição lista → detalhe (hero)

- A imagem de capa do card recebe `Hero(tag: 'cover-<id>')`; o topo do detalhe existente recebe o `Hero` correspondente como destino, para a foto "crescer" na navegação. Toque mínimo no `detail_page.dart`/`desvio_detail_page.dart` — apenas o alvo do hero. Redesenho completo do detalhe = Spec #2.

### 6. Dependências

- Adicionar **`cached_network_image`** ao `pubspec.yaml`.
- `flutter_animate` já presente.

---

## Testes

- **Widget test `EngCoverCard`** — os três caminhos de capa: nome de imagem → renderiza `EngAuthImage`; nome não-imagem → fallback documento; sem evidência → fallback neutro.
- **Widget test `EngAuthImage`** — passa o header Authorization; mostra placeholder e error builder.
- **Provider test `ocorrenciasProvider`** — parse de uma resposta `/api/ocorrencias` mockada, split correto por `tipo`, e montagem dos parâmetros `meuPapel` para EXTERNO.
- Smoke test de render dos dois feeds nos estados loading / data / empty / error.

---

## Specs seguintes (sequência)

- **Spec #2** — Detalhe de NC e Desvio (destino do hero, galeria de evidências com `EngAuthImage`, aplicação dos tokens).
- **Spec #3** — Dashboard.
- **Spec #4** — Wizard de registro + captura de foto.
- **Spec #5** — Perfil + login.

Todos reutilizam o kit do Spec #1.

---

## Riscos / pontos de atenção

- **`primeiraEvidencia` pode não ser imagem** — tratado pela lógica de extensão no `EngCoverCard`.
- **Preservar o palette aprovado** — a unificação adota os valores do `ProtoColors`, não os do `tokens.dart` divergente. Verificar durante a implementação que nenhuma tela "pula" de cor.
- **`meuPapel` no `/api/ocorrencias`** — confirmar no plano que os valores do enum (`RESPONSAVEL_TRATATIVA_NC`, etc.) cobrem exatamente o filtro de EXTERNO atual, para não regredir permissão.
