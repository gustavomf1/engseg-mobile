# Notificações Push — Fluxo de Não Conformidade (NC)

**Data:** 2026-06-18
**Projetos:** engseg-api, engseg-mobile-backend, engseg-mobile (Flutter)
**Status:** Aprovado para planejamento

---

## Contexto

O app mobile já tem a infraestrutura básica de push: `firebase_messaging` no Flutter, `DeviceToken` + `PushNotificationService` (Firebase Admin SDK) no `engseg-mobile-backend`, e um pipeline de eventos `engseg-api → Kafka (engseg.nc.events) → engseg-mobile-backend` que hoje serve para disparar e-mails (`NcEmailListener`) e replicar no Kafka.

Levantamento do estado atual:

1. **Bug de nomenclatura no contrato Kafka.** O record `NcKafkaEvent` (`engseg-api`) tem comentários trocados:
   ```java
   UUID responsavelId,         // comentário diz "responsavelTratativa"
   UUID responsavelTrativaId,  // comentário diz "responsavelNc"
   ```
   Rastreando `NcEmailListener.publicarKafka`, confirma-se que **`responsavelId` na prática carrega o `responsavelNc`**, e `responsavelTrativaId` carrega o `responsavelTratativa` — o oposto dos comentários.

2. **Lógica de destinatários incorreta como consequência.** `MobileKafkaConsumer.resolverDestinatariosNc`:
   - Na criação (`NC_CRIADA`): notifica responsavelNc + responsavelTratativa → **deveria notificar ninguém**.
   - Em qualquer transição seguinte: notifica só criador + responsavelNc → **nunca notifica o responsável pela tratativa**, que precisa ser notificado em várias transições do fluxo real.

3. **Sem payload `data` no push.** `PushNotificationService.enviarParaToken` só seta `Notification` (título/corpo). Não há como o app saber, ao tocar na notificação, qual NC abrir.

4. **Sem tratamento de toque no app.** `FcmService` só escuta `onMessage` (foreground) e mostra um `SnackBar` com botão "Ver" **vazio** (`onPressed: () {}`). Não há `onMessageOpenedApp` nem `getInitialMessage()`.

5. **Tela `/notif` 100% mockada.** `notif_page.dart` usa uma lista hardcoded (`_NotifItem`), com chips de filtro (`Todas/Atribuições/Prazos/Aprovações`) sem efeito real. Não existe, hoje, nenhuma estrutura de persistência de histórico de notificações no `engseg-mobile-backend`.

6. **`engseg-mobile-backend` não tem alarmes de duplicidade.** O consumer Kafka não é idempotente — uma redelivery (rebalance, retry) reprocessaria o evento. Hoje isso só duplica um push (efêmero); ao persistir histórico, duplicaria linhas permanentes na tela.

7. **Métodos legados ainda são usados pela web e não preenchem os campos por atividade.** `NaoConformidadeDetailPage.tsx`/`TrativaDetailPage.tsx` (engseg-web) ainda chamam `aprovar-plano`/`rejeitar-plano`/`aprovar-evidencias`/`rejeitar-evidencias`. Esses métodos legados:
   - `aprovarPlano`/`aprovarEvidencias`: nunca tocam `status`/`statusExecucao` de nenhuma atividade.
   - `rejeitarPlano`: seta `status="REJEITADA"` nas atividades pendentes, mas **nunca** seta `motivoRejeicao` por atividade (só existe um motivo único no nível da NC, via `request.motivo()`).
   - `rejeitarEvidencias`: não toca em nenhuma atividade.

   Se o builder de mensagem (item 2 da Arquitetura) confiar cegamente em `nc.getAtividades()`, uma rejeição feita pela web mostraria atividades sem motivo, ou pior — no caso de `rejeitarEvidencias`, atividades ainda marcadas `APROVADA` numa NC que acabou de ser reprovada. Tratado no item 2 com uma regra de fallback.

---

## Objetivo

Implementar notificações push corretas para o ciclo de vida de uma NC, com destinatários e conteúdo (incluindo detalhe por atividade aprovada/reprovada) de acordo com a regra de negócio descrita pelo usuário, e substituir a tela `/notif` mockada por um histórico real persistido.

## Escopo

- **Dentro:** fluxo de Não Conformidade (NC), Android, histórico real de notificações (`/notif`), deep-link ao tocar no push.
- **Fora desta rodada:** Desvio (mesma lógica poderá ser replicada depois, em spec futuro); iOS (device token já grava `plataforma: 'ANDROID'` fixo — não preparar iOS agora); badge de contagem não lida no ícone "Avisos" do shell (mencionado como possível extensão, não implementado aqui).

---

## Decisões (tomadas no brainstorming)

| Tema | Decisão |
|---|---|
| Onde calcular destinatários + texto | **`engseg-api`**, dentro de `NcEmailListener` (AFTER_COMMIT, já tem a NC fresca) — `engseg-mobile-backend` só persiste e dispara push |
| Contrato Kafka | Reescrito: `NcKafkaEvent(eventId, tipo, ncId, destinatarios, titulo, corpo)` — remove os campos ambíguos `responsavelId`/`responsavelTrativaId` |
| Identificador para deep-link | UUID da NC (`nc.getId()`), igual ao usado por `GET /api/nao-conformidades/{id}` — não um código legível |
| Validação final reprovada → destinatários | **Só responsavelTratativa** (literal à descrição original do usuário, diferente da reprovação de plano que inclui o criador) |
| Conclusão da NC → destinatários | **Os 3 envolvidos** (criador + responsavelNc + responsavelTratativa) |
| Filtros da tela `/notif` | **Removidos nesta rodada** — lista única, sem chips de categoria |
| Idempotência | `eventId` (UUID) gerado por publicação; consumer ignora se `eventId` já processado |

---

## Arquitetura

### 1. Contrato Kafka (engseg-api e engseg-mobile-backend)

Novo `NcKafkaEvent`, idêntico nos dois lados:

```java
public record NcKafkaEvent(
    UUID eventId,
    String tipo,
    UUID ncId,
    List<UUID> destinatarios,
    String titulo,
    String corpo
) {}
```

`tipo` é um dos: `NC_CRIADA`, `NC_ATIVADA`, `NC_PLANO_SUBMETIDO`, `NC_PLANO_APROVADO`, `NC_PLANO_REPROVADO`, `NC_EXECUCAO_SUBMETIDA`, `NC_CONCLUIDA`, `NC_VALIDACAO_REPROVADA`.

### 2. Resolução de destinatários e mensagem (engseg-api)

Nova classe `NcPushMessageBuilder` (chamada por `NcEmailListener.publicarKafka`, que já recebe `NaoConformidade nc` e `NcEmailEvent event` com `statusAnterior`/`statusNovo`). Resolve por par `(statusAnterior, statusNovo)`:

| statusAnterior → statusNovo | tipo | Destinatários | Detalhe |
|---|---|---|---|
| `null` → `ABERTA` | `NC_CRIADA` | nenhum (lista vazia) | — |
| `ABERTA` → `AGUARDANDO_TRATATIVA` | `NC_ATIVADA` | responsavelTratativa | — |
| `AGUARDANDO_TRATATIVA` → `AGUARDANDO_APROVACAO_PLANO` | `NC_PLANO_SUBMETIDO` | responsavelNc + criador | — |
| `AGUARDANDO_APROVACAO_PLANO` → `EM_EXECUCAO` | `NC_PLANO_APROVADO` | responsavelTratativa + criador | todas atividades aprovadas |
| `AGUARDANDO_APROVACAO_PLANO` → `EM_AJUSTE_PELO_EXTERNO` | `NC_PLANO_REPROVADO` | responsavelTratativa + criador | por atividade: ✅/❌ + motivo |
| `EM_EXECUCAO` → `AGUARDANDO_VALIDACAO_FINAL` | `NC_EXECUCAO_SUBMETIDA` | responsavelNc + criador | — |
| `AGUARDANDO_VALIDACAO_FINAL` → `CONCLUIDO` | `NC_CONCLUIDA` | criador + responsavelNc + responsavelTratativa | todas atividades aprovadas |
| `AGUARDANDO_VALIDACAO_FINAL` → `EM_EXECUCAO` | `NC_VALIDACAO_REPROVADA` | responsavelTratativa | por atividade: ✅/❌ + motivo |

Lista de destinatários é montada como `LinkedHashSet<UUID>` (dedup automático se a mesma pessoa ocupa dois papéis).

**Métodos legados** (`aprovarPlano`/`rejeitarPlano`/`aprovarEvidencias`/`rejeitarEvidencias`, todo-ou-nada) caem nas mesmas linhas da tabela para fins de **destinatários**, pois essa resolução é por par de status, não por método chamado. Para o **detalhe por atividade**, porém, precisam da regra de fallback descrita a seguir (ver item 7 do Contexto).

**Detalhe por atividade** — ao montar o `corpo` para `NC_PLANO_REPROVADO`/`NC_PLANO_APROVADO`, ler `atividade.getStatus()` + `atividade.getMotivoRejeicao()` (fase plano); para `NC_CONCLUIDA`/`NC_VALIDACAO_REPROVADA`, ler `atividade.getStatusExecucao()` + `atividade.getMotivoRejeicaoExecucao()` (fase execução) — **são pares de campos diferentes na mesma entidade `AtividadePlanoAcao`**, é fácil ler o par errado. Iterar `nc.getAtividades()` (já reflete as decisões recém-salvas, pois o listener roda AFTER_COMMIT).

Exemplo de corpo para `NC_PLANO_REPROVADO`:
```
Plano da NC "Vazamento na linha 3": ✅ Isolar a área aprovada · ❌ Treinar equipe reprovada — faltou cronograma
```

**Regra de fallback (cobre os métodos legados do item 7 do Contexto):** nos tipos de rejeição (`NC_PLANO_REPROVADO`, `NC_VALIDACAO_REPROVADA`), só enumerar por atividade se **pelo menos uma atividade tiver o motivo da fase corrente não-nulo** (`motivoRejeicao` ou `motivoRejeicaoExecucao`, conforme a fase) — sinal de que a ação veio de `revisarAtividades`/`revisarExecucao` (únicos métodos que preenchem motivo por atividade). Se nenhuma atividade tiver motivo na fase corrente (ação veio de `rejeitarPlano` ou `rejeitarEvidencias`), **não enumerar atividades** — usar só `event.getComentario()` (motivo único da rejeição) como corpo. Isso evita mostrar atividade sem motivo (`rejeitarPlano`) ou, pior, atividades ainda como `APROVADA` numa NC recém-reprovada (`rejeitarEvidencias`, que não toca nenhuma atividade). Nos tipos de aprovação total (`NC_PLANO_APROVADO`, `NC_CONCLUIDA`) não há necessidade de enumerar — corpo é uma confirmação genérica ("todas as atividades aprovadas"), o que também evita depender do status por atividade nesses casos (`aprovarPlano`/`aprovarEvidencias` nunca o atualizam).

### 3. Publicação (engseg-api)

`NcEmailListener.publicarKafka` passa a:
1. Gerar `eventId = UUID.randomUUID()`.
2. Chamar `NcPushMessageBuilder.resolver(nc, event.getStatusAnterior(), event.getStatusNovo())` → `(tipo, destinatarios, titulo, corpo)`.
3. Publicar o `NcKafkaEvent` enriquecido.

Nenhuma mudança nos pontos de chamada em `NaoConformidadeService` — o listener já tem tudo que precisa.

### 4. Consumo, idempotência e histórico (engseg-mobile-backend)

Nova entidade `NotificacaoHistorico`:

| Campo | Tipo |
|---|---|
| id | UUID |
| eventId | UUID |
| usuarioId | UUID |
| ncId | UUID |
| tipo | String |
| titulo | String |
| corpo | String |
| lida | boolean (default false) |
| criadoEm | LocalDateTime |

Constraint única em `eventId` (consulta `existsByEventId` no início do consumo — se já processado, ignora a mensagem inteira; cobre redelivery do Kafka).

`MobileKafkaConsumer` (lógica nova, substitui `resolverDestinatariosNc` e o switch de corpo — **ambos removidos**, deixam de ter razão de existir):
1. Se `existsByEventId(event.eventId())` → ignora (log de debug).
2. Se `destinatarios` vazio → ignora (caso `NC_CRIADA`).
3. Para cada destinatário: salva `NotificacaoHistorico` + dispara push via `PushNotificationService`.

`PushNotificationService.enviarParaToken` passa a incluir `data`:
```java
Message.builder()
    .setToken(fcmToken)
    .setNotification(...)
    .putData("ncId", ncId.toString())
    .putData("tipo", tipo)
    .build();
```

### 5. Endpoints REST de histórico (engseg-mobile-backend)

Novo `NotificacaoController`, seguindo o padrão anti-spoofing já usado em `DeviceTokenController` (`usuarioId` sempre de `@AuthenticationPrincipal AuthenticatedUser`, nunca do request):

- `GET /notificacoes?page=&size=` — paginado, mais recentes primeiro, do usuário autenticado.
- `POST /notificacoes/{id}/lida` — marca uma como lida (valida que a linha pertence ao usuário autenticado).
- `POST /notificacoes/lidas` — marca todas como lidas.
- `GET /notificacoes/nao-lidas/contagem` — contagem para uso futuro (badge).

### 6. Mobile — deep-link ao tocar no push

`FcmService` ganha:
- `FirebaseMessaging.onMessageOpenedApp.listen(...)` — app em background, usuário tocou na notificação do sistema.
- `FirebaseMessaging.instance.getInitialMessage()` — app estava fechado, foi aberto pelo toque.
- Ambos navegam via `navigatorKey.currentState!.context` + `context.push('/oc/${message.data['ncId']}')`.
- Corrige o botão "Ver" do `SnackBar` (`_showForegroundBanner`) para fazer a mesma navegação usando o `RemoteMessage` recebido.

### 7. Mobile — tela `/notif` real

- Novo `NotificacaoRepository` (interface + impl), espelhando o padrão de `nc_repository.dart`: `Future<List<NotificacaoItem>> listar({int page})`, `Future<void> marcarComoLida(String id)`.
- Provider Riverpod (`notificacoesProvider`) consumindo o repository.
- `notif_page.dart` reescrita: lista real, sem chips de filtro (removidos por decisão deste spec), pull-to-refresh, tap marca como lida + navega para `/oc/{ncId}` (escopo é só NC, então sempre essa rota).
- Ao receber push em foreground (`onMessage`), invalidar `notificacoesProvider` para a lista atualizar sem precisar reabrir a tela.

---

## Testes

- **`NcPushMessageBuilderTest`** (engseg-api): um caso por linha da tabela do item 2 — destinatários corretos, `tipo` correto, e para `NC_PLANO_REPROVADO`/`NC_VALIDACAO_REPROVADA` o corpo contém o motivo de cada atividade reprovada e não contém motivo para as aprovadas. Caso específico cobrindo a leitura do par de campos certo (`status`/`motivoRejeicao` vs `statusExecucao`/`motivoRejeicaoExecucao`) — uma atividade pode ter os dois pares preenchidos (já passou pela fase de plano e está na fase de execução) e o teste garante que o builder lê o par da fase corrente, não o outro. Casos extras simulando os métodos legados: nenhuma atividade com motivo na fase corrente → corpo cai no fallback (`event.getComentario()`), sem enumerar atividades.
- **Idempotência do consumer** (engseg-mobile-backend): publicar o mesmo `eventId` duas vezes → uma única linha de histórico por destinatário, um único push por destinatário.
- **`NotificacaoController`**: usuário A não consegue marcar como lida uma notificação de usuário B (403/404).
- **Manual no device físico** (Android): tocar no push com app fechado, em background e em foreground → cai na tela certa da NC nos três casos.

## Riscos / pontos de atenção

- Mudança de contrato do `NcKafkaEvent` é breaking — `engseg-api` e `engseg-mobile-backend` precisam subir juntos (ou o consumer tolerar o formato antigo por uma janela; não vale a complexidade para um tópico interno de dois serviços próprios — assumir deploy conjunto).
- `engseg-mobile-backend` não é um repositório git hoje (diferente de `engseg-api` e `engseg-mobile`) — fora do escopo deste spec, só registrado.
- Rejeições feitas pela web via endpoints legados geram notificação só com o motivo geral (fallback do item 2), sem o detalhamento por atividade que as ações feitas pelos métodos novos (`revisarAtividades`/`revisarExecucao`) produzem. É uma limitação aceita, não um bug do que está sendo construído aqui — corrigir de raiz exigiria alterar os métodos legados em `NaoConformidadeService` para preencher `motivoRejeicao`/`motivoRejeicaoExecucao` por atividade, o que está fora do escopo deste spec.
