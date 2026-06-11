# Design — Fluxos de Criação (foto-primeiro) e Desvio no app mobile EngSeg

**Data:** 2026-05-28
**Projeto:** `engseg-mobile` (Flutter · Riverpod · GoRouter · Dio · Drift)
**Autor:** brainstorming com o usuário

## 1. Contexto e objetivo

O app mobile já tem o fluxo de **Não Conformidade (NC)** funcional para
aprovação de plano de ação e execução (feed de NCs, `detail_page` com abas
Geral/Plano/Execução/Evidências, todo o workflow de status). Falta:

1. **Criar ocorrências** (NC e Desvio) a partir do app — não existe formulário de
   criação, apesar de os models `CriarNcRequest`/`CriarDesvioRequest` já
   existirem.
2. **Fluxo completo de Desvio** — o repositório só tem `listar/buscarPorId/criar`;
   não há tela de detalhe nem ações de tratativa.
3. **Pipeline foto → criar → upload** — a `camera_page` captura foto isolada, mas
   nada liga captura a criação de ocorrência.

O backend (`engseg-api`) já expõe **todos** os endpoints necessários; nenhuma
mudança de backend é requerida (apenas verificações pontuais — ver §10).

## 2. Escopo

**Dentro:**
- Pipeline de criação foto-primeiro para NC e Desvio.
- Formulário de criação de NC (com severidade/probabilidade/normas/responsáveis)
  e de Desvio (orientação/responsáveis).
- Editor de e-mails de notificação nos dois formulários.
- Tela de listagem de Desvios (separada da de NC).
- Tela de detalhe de Desvio + fluxo de tratativas com **paridade total** ao web
  (abrir tratativa, adicionar/submeter tratativas com evidências, aprovar/reprovar).

**Fora (YAGNI por ora):**
- Rascunho offline / sync (decisão: **online apenas**). A infra Drift/`drafts`
  existe mas não será usada neste ciclo.
- Edição/exclusão de ocorrências já criadas pelo mobile.

## 3. Decisões tomadas (brainstorming)

| Tema | Decisão |
|---|---|
| Ponto de entrada de criação | **Foto primeiro** (câmera → formulário → cria → sobe foto) |
| Tipos que o mobile pode criar | **Ambos** NC e Desvio |
| Profundidade do fluxo de Desvio | **Paridade total** com o web (inclui aprovar/reprovar) |
| Offline | **Online apenas** |
| Listagem de Desvios | **Tela separada** (não unificar com o feed de NC) |
| Campos de NC na criação | **Estender** `CriarNcRequest` com responsáveis + localização |
| E-mails de notificação | **Incluir editor** de e-mails nos formulários |

## 4. Arquitetura e navegação

Mantém o padrão atual (feature-first em `lib/features/ocorrencias`, Riverpod,
GoRouter, repositórios com interface + impl).

**Rotas (GoRouter) novas/alteradas em `core/router/app_router.dart`:**
- `/desvios` — nova `DesvioFeedPage` (lista de desvios), dentro do `ShellRoute`.
- `/desvio/:id` — nova `DesvioDetailPage`.
- `/wizard/:tipo` — passa a renderizar o **formulário de criação** (hoje
  `WizardPage` está vazia). Recebe a foto capturada via `state.extra`.
- `/camera?tipo=NC|DESVIO` — já existe; ao concluir a captura, navega para
  `/wizard/:tipo` carregando `File` + `EvidenciaMetadata` no `extra`.

**Entrada do usuário:**
- FAB "+" na `DesvioFeedPage` e no `feed_page` (NC) → abre bottom sheet com
  **NC** / **Desvio** → `/camera?tipo=...`.
- Item de navegação "Desvios" no `EngSegShell` (ao lado de NCs/Feed).

## 5. Fluxo 1 — Criação foto-primeiro (NC e Desvio)

**Sequência:**
1. Usuário toca "+", escolhe tipo → `/camera?tipo=NC|DESVIO`.
2. `camera_page` captura foto + metadados (lat/lon, cidade, `capturedAt`) e
   navega para `/wizard/:tipo` com `extra = { foto: File, meta: EvidenciaMetadata }`.
3. `WizardPage` mostra **formulário único rolável**:
   - **Preview** da foto no topo + chip de geolocalização.
   - **Comuns:** estabelecimento (`listarEstabelecimentos`), localização
     (`listarLocalizacoes(estabId)`), título, descrição, regra de ouro (switch),
     editor de e-mails (manuais + exclusão de padrões).
   - **Só Desvio:** orientação realizada (texto), responsável pelo desvio e
     responsável pela tratativa (`listarUsuarios(estabId)`).
   - **Só NC:** severidade (1–5), probabilidade (1–4) + nível de risco derivado,
     normas (multi-select `listarNormas`), reincidência (switch), responsável NC e
     responsável tratativa, localização.
4. **Salvar:**
   a. `criar(request)` → retorna `id` da ocorrência.
   b. `uploadParaNc/Desvio(id, foto, meta)` com `tipo=OCORRENCIA`.
   c. Navega para o detalhe correspondente (`/oc/:id` ou `/desvio/:id`).
5. Estados de loading e erro explícitos; se o upload da foto falhar após criar a
   ocorrência, manter a ocorrência criada e oferecer **retry do upload** (não
   recriar a ocorrência).

**Validação:** título e estabelecimento obrigatórios; NC exige severidade e
probabilidade. Validação client-side antes do submit.

## 6. Fluxo 2 — Desvio: detalhe + tratativas (paridade web)

**Estados do Desvio:** `ABERTO → AGUARDANDO_TRATATIVA → AGUARDANDO_APROVACAO → CONCLUIDO`.
Reprovação volta para nova rodada de tratativa.

**`DesvioDetailPage`** (espelha o padrão da `detail_page` de NC), seções:
- **Geral:** título, status (badge), orientação realizada, responsáveis, regra de
  ouro, evidência da ocorrência (foto).
- **Tratativas:** lista agrupada por **rodada**; cada `TrativaDesvio` mostra
  título, descrição, evidências (thumbnails), status (`PENDENTE`/`APROVADO`/
  `REPROVADO`) e motivo de reprovação quando houver.
- **Histórico:** linha do tempo (opcional, se `historico` vier no detalhe).

**Ações por status + perfil:**

| Status | Quem | Ação | Endpoint |
|---|---|---|---|
| `ABERTO` | responsável tratativa / ENGENHEIRO | Abrir tratativa | `POST /api/desvios/{id}/abrir-tratativa` |
| `AGUARDANDO_TRATATIVA` | responsável tratativa | Adicionar tratativa (título, descrição, evidências) | `POST /api/desvios/{id}/tratativas` |
| `AGUARDANDO_TRATATIVA` | responsável tratativa | Remover tratativa pendente | `DELETE /api/desvios/{id}/tratativas/{trativaId}` |
| `AGUARDANDO_TRATATIVA` | responsável tratativa | Submeter tratativas | `POST /api/desvios/{id}/submeter-tratativa` |
| `AGUARDANDO_APROVACAO` | responsável desvio / ENGENHEIRO | Aprovar | `POST /api/desvios/{id}/aprovar` |
| `AGUARDANDO_APROVACAO` | responsável desvio / ENGENHEIRO | Reprovar (com motivo) | `POST /api/desvios/{id}/reprovar` |

**Adicionar tratativa com fotos:** capturar foto(s) → upload em
`POST /api/evidencias/desvio/{desvioId}` com `tipo=TRATATIVA` → coletar os
`evidenciaId` retornados → `POST /tratativas` com `{ titulo, descricao, evidenciaIds[] }`.

**Permissões (do web, ver memória de permissões TECNICO):**
- TECNICO só age na tratativa de Desvio se for o `responsavelTratativaId`.
- Aprovar/reprovar é gateado por `responsavelDesvioId` (ou ADMIN/ENGENHEIRO).

## 7. Models novos (`lib/features/ocorrencias/model`)

- `DesvioDetail` — id, titulo, descricao, status, orientacaoRealizada,
  regraDeOuro, responsavelDesvioId/Nome, responsavelTratativaId/Nome,
  estabelecimentoNome, dataRegistro, evidencias[], tratativas[], historico[].
- `TrativaDesvio` — id, titulo, descricao, status (`PENDENTE`/`APROVADO`/
  `REPROVADO`), motivoReprovacao?, rodada, numero, dtCriacao, evidencias[].
- `HistoricoDesvio` — tipoAcao, descricao, autor, data (se exposto pelo backend).

`DesvioSummary` permanece para a listagem (já existe).

## 8. Repositórios (`repository`)

**Estender `DesvioRepository`** (interface + impl) com:
- `abrirTratativa(id)`
- `adicionarTratativa(id, AdicionarTrativaRequest)`
- `removerTratativa(id, trativaId)`
- `submeterTratativa(id, SubmeterTrativaDesvioRequest)`
- `aprovar(id, AprovarDesvioRequest)`
- `reprovar(id, ReprovarTrativasDesvioRequest)`
- alterar `buscarPorId` para retornar `DesvioDetail` (hoje retorna `Map`).

**`EvidenciaRepository`:** `uploadParaDesvio` já existe; garantir suporte ao
parâmetro `tipo` (`OCORRENCIA` vs `TRATATIVA`).

**Novos request models:** `AdicionarTrativaRequest`, `SubmeterTrativaDesvioRequest`,
`AprovarDesvioRequest`, `ReprovarTrativasDesvioRequest`.

**Estender `CriarNcRequest`** com `localizacaoId?`, `responsavelNcId?`,
`responsavelTrativaId?`. Estender `CriarDesvioRequest` com `localizacaoId?`.

## 9. Providers (Riverpod)

- `desvioListProvider({estabelecimentoId})`, `desvioDetailProvider(id)`.
- `supportProvider`-style para estabelecimentos/normas/usuários/localizações
  (reusar o que já alimenta a NC, se existir; senão criar).
- Providers de submit (criar ocorrência, ações de tratativa) com estado
  loading/erro/sucesso para a UI reagir.

## 10. Dependências de backend a verificar (antes de implementar)

1. **Forma exata do `DesvioResponse`** (campos de detalhe, tratativas aninhadas,
   evidências, histórico) — para mapear `DesvioDetail`/`TrativaDesvio`.
2. **`AdicionarTrativaRequest`** — confirmar campos (`titulo`, `descricao`,
   `evidenciaIds[]`).
3. **`tipo=TRATATIVA`** no upload de evidência de desvio — confirmar enum aceito
   em `POST /api/evidencias/desvio/{id}`.
4. **E-mails padrão** — endpoint para listar e-mails padrão (para o editor poder
   exibir e permitir excluir). Há a feature `EmailPadraoNc`; confirmar se há
   equivalente para Desvio e o endpoint de leitura.

## 11. Arquivos — novos e modificados

**Novos:**
- `lib/features/ocorrencias/desvio_feed_page.dart`
- `lib/features/ocorrencias/desvio_detail_page.dart`
- `lib/features/ocorrencias/model/desvio_detail.dart`
- `lib/features/ocorrencias/model/trativa_desvio.dart`
- `lib/features/ocorrencias/model/historico_desvio.dart` (se aplicável)
- request models: `adicionar_trativa_request.dart`, `submeter_trativa_desvio_request.dart`, `aprovar_desvio_request.dart`, `reprovar_trativas_desvio_request.dart`
- widget(s): seletor NC/Desvio (bottom sheet), editor de e-mails, picker de risco NC.

**Modificados:**
- `lib/features/wizard/wizard_page.dart` (formulário de criação real)
- `lib/features/capture/camera_page.dart` (handoff câmera → wizard com `extra`)
- `lib/features/ocorrencias/repository/desvio_repository.dart` (+ impl)
- `lib/features/ocorrencias/repository/evidencia_repository.dart` (+ impl, `tipo`)
- `lib/features/ocorrencias/model/criar_nc_request.dart` e `criar_desvio_request.dart`
- `lib/core/router/app_router.dart` (rotas `/desvios`, `/desvio/:id`)
- `lib/shared/widgets/engseg_shell.dart` (entrada "Desvios" na navegação)
- `lib/features/ocorrencias/feed_page.dart` (FAB de criação)

## 12. Riscos e pontos de atenção

- **Upload parcial:** se a ocorrência for criada e o upload da foto falhar,
  precisamos de retry sem duplicar a ocorrência (ver §5.5).
- **Editor de e-mails depende** do endpoint de e-mails padrão (§10.4); se não
  existir para Desvio, o editor só permite adicionar manuais.
- **Permissões:** replicar com cuidado as regras de TECNICO/EXTERNO para não
  expor ações indevidas (ver memória de permissões).
- **Nomenclatura:** usar os nomes canônicos atuais (`responsavelTratativa`,
  `responsavelDesvio`, `responsavelNc`) — nada de `engConstrutora/engVerificacao`.

## 13. Ordem sugerida de implementação

1. Estender models de request + criar request models de desvio.
2. Estender `DesvioRepository`/impl e `EvidenciaRepository` (+ providers).
3. Pipeline de criação: `camera_page` handoff → `WizardPage` (Desvio primeiro,
   depois NC) → criar + upload.
4. `DesvioFeedPage` + rota + entrada na navegação.
5. `DesvioDetailPage` + ações de tratativa (paridade).
6. Editor de e-mails e picker de risco como widgets reutilizáveis.
7. Teste manual no Redmi Note 7 (device `f868b62`) ponta a ponta.
