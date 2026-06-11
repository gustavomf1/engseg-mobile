# Revisão individual de tratativas no mobile (Desvio)

## Contexto

No web (`DesvioTrativaSection.tsx`), quando um Desvio está `AGUARDANDO_APROVACAO` e o
usuário logado é o `responsavelDesvio`, a tela mostra uma seção "Revisar Tratativas"
onde cada tratativa pendente tem um checkbox "Reprovar". Marcar o checkbox revela um
campo de motivo obrigatório. Se nenhuma tratativa for marcada, um campo de comentário
opcional aparece e o botão final aprova todas; se alguma for marcada, o botão reprova
apenas as marcadas (o backend aprova implicitamente as demais da rodada).

No mobile (`desvio_detail_page.dart`), a mesma situação mostra dois botões separados:
"Aprovar" (sempre aprova tudo, sem comentário) e "Reprovar" (abre um `AlertDialog`
com um campo de texto "Motivo" por tratativa pendente — preencher o motivo marca
implicitamente aquele item para reprovação). Se o usuário deixar todos os campos
vazios e confirmar, nada acontece (no-op silencioso).

O backend (`DesvioService.reprovar`) já suporta reprovação parcial: itens não
incluídos em `request.itens()` são aprovados automaticamente. Nenhuma mudança de
backend é necessária.

## Objetivo

Dar ao mobile o mesmo fluxo de revisão do web: uma seção inline única, com checkbox
"Reprovar" por item + motivo condicional, comentário opcional de aprovação, e um
único botão de confirmação que muda de rótulo conforme o estado.

## Escopo

- Novo widget `RevisarTratativasSection` em
  `lib/features/ocorrencias/widgets/revisar_tratativas_section.dart`.
- Substituição, em `desvio_detail_page.dart`, dos botões "Aprovar"/"Reprovar" (caso
  `AGUARDANDO_APROVACAO` + `isApprover`) por essa nova seção.
- Remoção do método `_openReprovar()` e do `AlertDialog` associado.
- Sem alterações no backend, nos modelos de request (`AprovarDesvioRequest`,
  `ReprovarTrativasDesvioRequest`, `ItemReprovacao` já têm os campos necessários) ou
  no `desvio_repository`.
- A seção `_tratativasSection()` (cards somente-leitura "Tratativas / Rodada N")
  permanece sem alteração.

## Design

### Widget `RevisarTratativasSection`

`StatefulWidget` que recebe:
- `DesvioDetail d`
- `String? token` (para exibir miniaturas de evidência)
- `Future<void> Function(Future<void> Function() action) runAction` — repassa para o
  `_run()` de `_BodyState`, que já trata loading/erro/invalidations.

Estado interno:
- `Map<String, bool> _reprovarMarcado` — uma entrada por tratativa pendente da rodada
  atual (`d.tratativas.where((t) => t.rodada == d.rodadaAtual && t.status == 'PENDENTE')`),
  inicializado em `false`.
- `Map<String, TextEditingController> _motivoControllers` — um por tratativa
  pendente, criado no `initState`, descartado no `dispose`.
- `TextEditingController _comentarioController` — comentário opcional de aprovação.

### Card por tratativa pendente

Cada item é um `ProtoCard` com:
- Título, descrição e miniaturas de evidência (reaproveita o padrão visual de
  `_tratativaCard`/`_thumbFallback`).
- Linha à direita com `Checkbox` + texto "Reprovar" em `ProtoColors.red`.
- Quando marcado:
  - Borda do card muda para `ProtoColors.red`.
  - Abaixo, `TextField` "Motivo da reprovação (obrigatório)" ligado ao
    `_motivoControllers[t.id]`.

### Rodapé

- Se nenhum item estiver marcado:
  - `TextField` opcional "Comentário" (`_comentarioController`).
  - Botão verde "Aprovar Todas" → `runAction(() => repo.aprovar(d.id, AprovarDesvioRequest(comentario: _comentarioController.text.trim().isEmpty ? null : _comentarioController.text.trim())))`.
- Se algum item estiver marcado:
  - Campo de comentário oculto.
  - Botão vermelho "Reprovar N tratativa(s)" (N = quantidade marcada) →
    valida que todos os itens marcados têm motivo não vazio; se algum estiver vazio,
    mostra `SnackBar` de erro e cancela. Caso contrário, chama
    `runAction(() => repo.reprovar(d.id, ReprovarTrativasDesvioRequest(itens: [...])))`
    apenas com os itens marcados.

### Integração em `desvio_detail_page.dart`

No método `_actions()`, o case `AGUARDANDO_APROVACAO` para `isApprover` passa a
retornar `[RevisarTratativasSection(d: d, token: _token, runAction: _run)]` em vez
dos dois `_btn(...)`. O método `_openReprovar()` e o `AlertDialog` correspondente são
removidos. Nenhuma outra branch de `_actions()` é alterada.

## Testes

- Teste de widget cobrindo:
  - Render inicial (nenhum item marcado): botão "Aprovar Todas", campo de comentário
    visível.
  - Marcar um item: campo de motivo aparece, campo de comentário some, botão muda
    para "Reprovar 1 tratativa(s)".
  - Tentar confirmar reprovação com motivo vazio: mostra erro, não chama o
    repositório.
  - Confirmar reprovação com motivo preenchido: chama `reprovar` com os itens
    corretos.
  - Confirmar aprovação (nenhum marcado): chama `aprovar` com o comentário
    informado (ou `null` se vazio).
