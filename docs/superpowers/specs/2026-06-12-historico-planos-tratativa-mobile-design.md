# Histórico de Planos de Tratativa + toggle Aprovar/Reprovar (mobile)

## Contexto

Hoje, `_tratativasSection()` em `desvio_detail_page.dart` agrupa `d.tratativas` por
`rodada` e renderiza cada rodada como uma lista plana de cards (`_tratativaCard`),
sem indicar visualmente qual rodada/plano foi reprovado nem permitir recolher
rodadas antigas. No web (`DesvioTrativaSection.tsx`), a seção equivalente
("O que foi submetido") agrupa por "Plano", mostra um selo de resultado
(Reprovado/Aprovado/Em análise), permite recolher cada plano e destaca em
vermelho o motivo de reprovação de cada tratativa.

Além disso, em `RevisarTratativasSection` (criada em
[2026-06-11-revisar-tratativas-mobile-design.md](2026-06-11-revisar-tratativas-mobile-design.md)),
cada tratativa pendente só tem um `Checkbox` "Reprovar" — deixar desmarcado
significa "aprovar implicitamente". Isso deixa a ação de aprovação individual
implícita demais.

## Objetivo

1. Redesenhar `_tratativasSection()` como um histórico de "Planos" (um por
   rodada), recolhível, com o plano reprovado sinalizado em vermelho com
   detalhes (motivo, quem reprovou, quando).
2. Em `RevisarTratativasSection`, substituir o `Checkbox` "Reprovar" por duas
   pílulas "Aprovar"/"Reprovar" por item, deixando a decisão explícita nos dois
   sentidos — sem alterar o comportamento de envio (backend já aprova
   implicitamente os itens não marcados para reprovação).

## Escopo

- `lib/features/ocorrencias/desvio_detail_page.dart`: nova lógica de
  agrupamento em "Planos", novo `_tratativasSection()`/`_planoCard()`/
  `_tratativaItemCard()`, novo estado `_planosExpandidos`.
- `lib/features/ocorrencias/widgets/revisar_tratativas_section.dart`: troca do
  `Checkbox` por par de pílulas Aprovar/Reprovar; troca de
  `Map<String, bool> _reprovarMarcado` por `Map<String, bool?> _decisao`.
- `test/features/ocorrencias/widgets/revisar_tratativas_section_test.dart`:
  ajustar para os novos controles.
- Novo teste de widget/unidade para a montagem dos "Planos" e renderização do
  histórico em `desvio_detail_page.dart`.
- Sem mudanças de backend, modelos de request ou `desvio_repository`. Sem
  mudanças no fluxo de NC (não tem `rodada`/`tratativas`).

## Design

### 1. Agrupamento em "Planos"

Nova função privada `_buildPlanos(DesvioDetail d)` em `desvio_detail_page.dart`,
portando `buildPlanos` de `DesvioTrativaSection.tsx`:

```dart
class _Plano {
  final int rodada;
  final List<TrativaDesvio> tratativas;
  final String resultado; // 'REPROVADO' | 'APROVADO' | 'EM_ANALISE'
  final String? dataSubmissao;
  final String? dataResultado;
  final String? revisorNome;
  final String? comentario;
}
```

- Agrupa `d.tratativas` por `rodada`, ordena cada grupo por `numero`.
- Percorre `d.historico` separando entradas com `tipo == 'TRATATIVA_SUBMETIDA'`
  (submissões) de `tipo == 'APROVADO' || tipo == 'REPROVADO'` (resultados).
- Para a rodada de índice `i` (rodadas ordenadas ascendentemente), casa com
  `submissoes[i]` e `resultados[i]` — mesma estratégia por índice do web.
- `resultado`:
  - se houver `resultado[i]`: `REPROVADO` ou `APROVADO` conforme `tipo`;
  - senão: `REPROVADO` se alguma tratativa da rodada está `REPROVADO`,
    `APROVADO` se todas estão `APROVADO`, caso contrário `EM_ANALISE`.

### 2. `_tratativasSection()` → histórico de Planos

- `_sectionLabel('Planos de Tratativa (N)')` com `N = planos.length`.
- Cada plano é um `ProtoCard` (`padding: EdgeInsets.zero`) com `Border` +
  `Container` decorado para simular borda esquerda de 4px:
  - `REPROVADO` → vermelho (`ProtoColors.red`)
  - `APROVADO` → verde (`ProtoColors.green`)
  - `EM_ANALISE` → azul (`ProtoColors.blue`)
- Cabeçalho (`InkWell` para tap): `"Plano $rodada"`, data de submissão
  (`_fmtDateTime(dataSubmissao)`, se houver), `ProtoPill` com o rótulo do
  resultado ("Reprovado"/"Aprovado"/"Em análise") nas cores acima, e um ícone de
  chevron (`Icons.expand_more`/`Icons.expand_less`) que reflete
  `_planosExpandidos.contains(rodada)`.
- Se o plano estiver recolhido e `resultado == 'REPROVADO'`, mostra abaixo do
  cabeçalho uma linha discreta `"Reprovado por $revisorNome • $dataResultado"`
  em `ProtoColors.red` (visível mesmo recolhido, conforme pedido do usuário).
- Conteúdo expandido (`if (_planosExpandidos.contains(rodada))`):
  - se `resultado == 'APROVADO'` e `comentario != null`, caixa verde
    "Comentário: ...";
  - lista de `_tratativaItemCard(t)` para cada tratativa do plano;
  - rodapé `"Reprovado/Aprovado por $revisorNome • $dataResultado"` (mesmo texto
    da versão recolhida, sem repetir se já mostrado lá — ou seja, o rodapé só
    aparece quando expandido).

### 3. `_tratativaItemCard(TrativaDesvio t)` (renomeado de `_tratativaCard`)

Mesma estrutura visual atual (título, `ProtoPill` de status, descrição,
evidências), com tingimento por status:

- `APROVADO` → `ProtoCard(color: ...verde translúcido, border: verde)`
- `REPROVADO` → `ProtoCard(color: ...vermelho translúcido, border: vermelho)` +
  caixa destacada `"Motivo: ${t.motivoReprovacao}"` em vermelho (já existe hoje,
  mantém)
- `PENDENTE` → estilo neutro atual

### 4. Estado de expansão

Em `_BodyState`:

```dart
Set<int>? _planosExpandidos;

Set<int> _expandidos(List<_Plano> planos) =>
    _planosExpandidos ??= {if (planos.isNotEmpty) planos.last.rodada};
```

Lazy-init na primeira `build`: por padrão só o último plano (rodada atual) vem
expandido — planos reprovados anteriores ficam recolhidos, mas com a borda e o
selo vermelhos visíveis. Tap no cabeçalho chama
`setState(() => _planosExpandidos!.contains(r) ? ...remove : ...add)`.

### 5. `RevisarTratativasSection` — pílulas Aprovar/Reprovar

- Estado: `Map<String, bool?> _decisao` (`null` = neutro, `true` = reprovar,
  `false` = aprovar), inicializado em `null` para cada tratativa pendente
  (substitui `Map<String, bool> _reprovarMarcado`).
- `_itemCard(t)`: à direita, duas pílulas lado a lado
  (`_DecisaoPill(label: 'Aprovar', color: ProtoColors.green, selecionado: ...)`
  e `_DecisaoPill(label: 'Reprovar', color: ProtoColors.red, selecionado: ...)`).
  - Tap numa pílula não selecionada: seleciona ela, desmarca a outra
    (`_decisao[t.id] = true/false`).
  - Tap na pílula já selecionada: volta para neutro (`_decisao[t.id] = null`).
  - Borda do `ProtoCard` do item acompanha: vermelho se `true`, verde se
    `false`, `ProtoColors.border` se `null`.
  - Campo de motivo (`TextField`) continua aparecendo só quando
    `_decisao[t.id] == true`, igual a hoje.
- `_algumaMarcada` = `_decisao.values.any((v) => v == true)` — mesma semântica
  de antes. Lógica de `_confirmar()`, rótulo do botão ("Aprovar Todas" /
  "Reprovar N tratativa(s)") e os requests `AprovarDesvioRequest` /
  `ReprovarTrativasDesvioRequest` **não mudam**.

## Testes

- `revisar_tratativas_section_test.dart`:
  - trocar `find.byType(Checkbox)` por `find.text('Reprovar')` /
    `find.text('Aprovar')` nos taps;
  - novo caso: tocar "Reprovar" e depois "Aprovar" no mesmo item volta ao
    botão "Aprovar Todas" (decisão neutralizada);
  - manter os casos existentes de validação de motivo vazio e dos requests
    enviados.
- Novo arquivo (ou seção em `desvio_detail_test.dart`/novo widget test) para
  `_buildPlanos`:
  - 2 planos (rodada 1 reprovado com 1 tratativa reprovada + 1 aprovada,
    rodada 2 em análise) → `_buildPlanos` retorna `resultado` corretos e
    `revisorNome`/`dataResultado` do plano 1;
  - render: plano 1 recolhido por padrão com borda/selo vermelhos e linha
    "Reprovado por ...", plano 2 expandido por padrão.

## Fora de escopo

- Fluxo de NC (sem `rodada`/`tratativas`, não é afetado).
- Tela "Adicionar tratativa" / formulário de nova tratativa.
- Mudanças de backend ou nos DTOs de request.
