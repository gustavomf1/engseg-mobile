# Revisão individual de tratativas no mobile (Desvio) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dar ao mobile o mesmo fluxo de revisão de tratativas do web: uma seção
"Revisar Tratativas" com checkbox "Reprovar" por item + motivo condicional,
comentário opcional de aprovação, e um único botão de confirmação.

**Architecture:** Novo widget `RevisarTratativasSection`
(`ConsumerStatefulWidget`) em `lib/features/ocorrencias/widgets/`, que recebe o
`DesvioDetail`, o token JWT (para miniaturas de evidência) e um callback
`runAction` (o `_run` já existente em `_BodyState`). Ele substitui os botões
"Aprovar"/"Reprovar" e o `_openReprovar()` em `desvio_detail_page.dart` para o
caso `AGUARDANDO_APROVACAO` + aprovador. Sem mudanças de backend — o endpoint
`/api/desvios/{id}/reprovar` já aprova implicitamente as tratativas não
incluídas em `itens`.

**Tech Stack:** Flutter, flutter_riverpod, mocktail (testes), flutter_test.

---

### Task 1: Widget `RevisarTratativasSection` — renderização e seleção de itens

**Files:**
- Create: `lib/features/ocorrencias/widgets/revisar_tratativas_section.dart`
- Test: `test/features/ocorrencias/widgets/revisar_tratativas_section_test.dart`

- [ ] **Step 1: Escrever os testes de renderização (devem falhar)**

Crie o diretório de teste e o arquivo:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/features/ocorrencias/model/desvio_detail.dart';
import 'package:engseg_mobile/features/ocorrencias/model/trativa_desvio.dart';
import 'package:engseg_mobile/features/ocorrencias/widgets/revisar_tratativas_section.dart';

DesvioDetail _buildDesvio() => const DesvioDetail(
      id: 'd-1',
      titulo: 'Desvio de teste',
      status: 'AGUARDANDO_APROVACAO',
      tratativas: [
        TrativaDesvio(
          id: 't-1',
          titulo: 'Tratativa 1',
          descricao: 'Descrição 1',
          status: 'PENDENTE',
          numero: 1,
          rodada: 1,
        ),
        TrativaDesvio(
          id: 't-2',
          titulo: 'Tratativa 2',
          descricao: 'Descrição 2',
          status: 'PENDENTE',
          numero: 2,
          rodada: 1,
        ),
      ],
    );

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  testWidgets('estado inicial mostra comentário opcional e botão Aprovar Todas',
      (tester) async {
    await tester.pumpWidget(_wrap(RevisarTratativasSection(
      d: _buildDesvio(),
      token: null,
      runAction: (action) => action(),
    )));

    expect(find.text('Revisar Tratativas'), findsOneWidget);
    expect(find.text('Tratativa 1'), findsOneWidget);
    expect(find.text('Tratativa 2'), findsOneWidget);
    expect(find.text('Aprovar Todas'), findsOneWidget);
    expect(find.text('Observações sobre a aprovação...'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(2));
    expect(find.text('Motivo da reprovação (obrigatório)'), findsNothing);
  });

  testWidgets('marcar reprovar exibe motivo obrigatório e muda o botão',
      (tester) async {
    await tester.pumpWidget(_wrap(RevisarTratativasSection(
      d: _buildDesvio(),
      token: null,
      runAction: (action) => action(),
    )));

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    expect(find.text('Motivo da reprovação (obrigatório)'), findsOneWidget);
    expect(find.text('Observações sobre a aprovação...'), findsNothing);
    expect(find.text('Reprovar 1 tratativa(s)'), findsOneWidget);
    expect(find.text('Aprovar Todas'), findsNothing);
  });
}
```

- [ ] **Step 2: Rodar os testes e confirmar que falham**

Run: `cd /home/mag/Documents/mobile/engseg-mobile && flutter test test/features/ocorrencias/widgets/revisar_tratativas_section_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:engseg_mobile/features/ocorrencias/widgets/revisar_tratativas_section.dart'` (o widget ainda não existe).

- [ ] **Step 3: Implementar o widget**

Crie `lib/features/ocorrencias/widgets/revisar_tratativas_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/prototype_ui.dart';
import '../model/desvio_action_requests.dart';
import '../model/desvio_detail.dart';
import '../model/trativa_desvio.dart';
import '../repository/desvio_repository_impl.dart';

/// Seção de revisão de tratativas exibida ao aprovador quando o Desvio está
/// AGUARDANDO_APROVACAO. Cada tratativa pendente pode ser marcada como
/// "Reprovar" (com motivo obrigatório); se nenhuma for marcada, um comentário
/// opcional pode ser informado para a aprovação total.
class RevisarTratativasSection extends ConsumerStatefulWidget {
  final DesvioDetail d;
  final String? token;
  final Future<void> Function(Future<void> Function() action) runAction;

  const RevisarTratativasSection({
    super.key,
    required this.d,
    required this.token,
    required this.runAction,
  });

  @override
  ConsumerState<RevisarTratativasSection> createState() =>
      _RevisarTratativasSectionState();
}

class _RevisarTratativasSectionState
    extends ConsumerState<RevisarTratativasSection> {
  late final List<TrativaDesvio> _pendentes;
  late final Map<String, bool> _reprovarMarcado;
  late final Map<String, TextEditingController> _motivoControllers;
  late final TextEditingController _comentarioController;

  @override
  void initState() {
    super.initState();
    _pendentes = widget.d.tratativas
        .where((t) =>
            t.rodada == widget.d.rodadaAtual && t.status == 'PENDENTE')
        .toList();
    _reprovarMarcado = {for (final t in _pendentes) t.id: false};
    _motivoControllers = {
      for (final t in _pendentes) t.id: TextEditingController(),
    };
    _comentarioController = TextEditingController();
  }

  @override
  void dispose() {
    for (final c in _motivoControllers.values) {
      c.dispose();
    }
    _comentarioController.dispose();
    super.dispose();
  }

  bool get _algumaMarcada => _reprovarMarcado.values.any((v) => v);

  @override
  Widget build(BuildContext context) {
    final marcadas = _reprovarMarcado.values.where((v) => v).length;
    return ProtoCard(
      border: Border.all(color: ProtoColors.blue, width: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProtoSectionTitle('Revisar Tratativas'),
          const SizedBox(height: 4),
          const Text(
            'Marque as que devem ser reprovadas e informe o motivo',
            style: TextStyle(color: ProtoColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          ..._pendentes.map(_itemCard),
          if (!_algumaMarcada) ...[
            const Text(
              'COMENTÁRIO (OPCIONAL)',
              style: TextStyle(
                color: Color(0xFFD7E8FF),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: .4,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _comentarioController,
              style: const TextStyle(color: ProtoColors.text, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Observações sobre a aprovação...',
                hintStyle:
                    const TextStyle(color: ProtoColors.muted, fontSize: 12),
                filled: true,
                fillColor: ProtoColors.surface2,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: ProtoColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: ProtoColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: ProtoColors.blue, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _algumaMarcada ? ProtoColors.red : ProtoColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {},
              child: Text(
                _algumaMarcada
                    ? 'Reprovar $marcadas tratativa(s)'
                    : 'Aprovar Todas',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(TrativaDesvio t) {
    final marcado = _reprovarMarcado[t.id] ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ProtoCard(
        border:
            Border.all(color: marcado ? ProtoColors.red : ProtoColors.border),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.titulo,
                        style: const TextStyle(
                          color: ProtoColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.descricao,
                        style: const TextStyle(
                          color: ProtoColors.muted,
                          fontSize: 13,
                        ),
                      ),
                      if (t.evidencias.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 56,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: t.evidencias.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 6),
                            itemBuilder: (_, i) {
                              final url = t.evidencias[i].url;
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: url != null
                                    ? Image(
                                        image: NetworkImage(
                                          url,
                                          headers: widget.token != null
                                              ? {
                                                  'Authorization':
                                                      'Bearer ${widget.token}',
                                                }
                                              : {},
                                        ),
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _thumbFallback(),
                                      )
                                    : _thumbFallback(),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: marcado,
                      activeColor: ProtoColors.red,
                      onChanged: (v) => setState(
                          () => _reprovarMarcado[t.id] = v ?? false),
                    ),
                    const Text(
                      'Reprovar',
                      style: TextStyle(
                        color: ProtoColors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (marcado) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _motivoControllers[t.id],
                maxLines: 2,
                style: const TextStyle(color: ProtoColors.text, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Motivo da reprovação (obrigatório)',
                  hintStyle: const TextStyle(
                      color: ProtoColors.muted, fontSize: 12),
                  filled: true,
                  fillColor: ProtoColors.surface2,
                  contentPadding: const EdgeInsets.all(10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: ProtoColors.red),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: ProtoColors.red),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: ProtoColors.red, width: 1.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _thumbFallback() => Container(
        width: 56,
        height: 56,
        color: ProtoColors.surface2,
        child: const Icon(Icons.image_outlined, color: ProtoColors.muted),
      );
}
```

Note: o botão de confirmação tem `onPressed: () {}` por enquanto — será
implementado na Task 2.

- [ ] **Step 4: Rodar os testes e confirmar que passam**

Run: `cd /home/mag/Documents/mobile/engseg-mobile && flutter test test/features/ocorrencias/widgets/revisar_tratativas_section_test.dart`
Expected: PASS (2 testes)

- [ ] **Step 5: Commit**

```bash
cd /home/mag/Documents/mobile/engseg-mobile
git add lib/features/ocorrencias/widgets/revisar_tratativas_section.dart test/features/ocorrencias/widgets/revisar_tratativas_section_test.dart
git commit -m "feat: widget RevisarTratativasSection com seleção por item"
```

---

### Task 2: Confirmar revisão — validação e chamadas ao repositório

**Files:**
- Modify: `lib/features/ocorrencias/widgets/revisar_tratativas_section.dart`
- Test: `test/features/ocorrencias/widgets/revisar_tratativas_section_test.dart`

- [ ] **Step 1: Escrever os testes de confirmação (devem falhar)**

Adicione ao final do `main()` em
`test/features/ocorrencias/widgets/revisar_tratativas_section_test.dart`
(ajuste os imports do topo do arquivo conforme indicado abaixo):

Adicione estes imports no topo do arquivo, junto aos demais:

```dart
import 'package:mocktail/mocktail.dart';
import 'package:engseg_mobile/features/ocorrencias/model/desvio_action_requests.dart';
import 'package:engseg_mobile/features/ocorrencias/repository/desvio_repository.dart';
import 'package:engseg_mobile/features/ocorrencias/repository/desvio_repository_impl.dart';

class MockDesvioRepository extends Mock implements DesvioRepository {}

Widget _wrapWithRepo(Widget child, DesvioRepository repo) => ProviderScope(
      overrides: [desvioRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
```

E adicione, dentro de `main()`, antes dos `testWidgets` já existentes:

```dart
  setUpAll(() {
    registerFallbackValue(const AprovarDesvioRequest());
    registerFallbackValue(const ReprovarTrativasDesvioRequest(itens: []));
  });
```

E os três novos testes (após os dois já existentes):

```dart
  testWidgets(
      'reprovar com motivo vazio mostra erro e não chama o repositório',
      (tester) async {
    final repo = MockDesvioRepository();
    when(() => repo.reprovar(any(), any())).thenAnswer((_) async {});

    await tester.pumpWidget(_wrapWithRepo(
      RevisarTratativasSection(
        d: _buildDesvio(),
        token: null,
        runAction: (action) => action(),
      ),
      repo,
    ));

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    await tester.tap(find.text('Reprovar 1 tratativa(s)'));
    await tester.pumpAndSettle();

    expect(
      find.text(
          'Preencha o motivo de todas as tratativas marcadas para reprovação.'),
      findsOneWidget,
    );
    verifyNever(() => repo.reprovar(any(), any()));
  });

  testWidgets(
      'reprovar com motivo preenchido chama o repositório com o item marcado',
      (tester) async {
    final repo = MockDesvioRepository();
    when(() => repo.reprovar(any(), any())).thenAnswer((_) async {});

    await tester.pumpWidget(_wrapWithRepo(
      RevisarTratativasSection(
        d: _buildDesvio(),
        token: null,
        runAction: (action) => action(),
      ),
      repo,
    ));

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Faltou anexar o laudo');
    await tester.tap(find.text('Reprovar 1 tratativa(s)'));
    await tester.pumpAndSettle();

    final captured =
        verify(() => repo.reprovar('d-1', captureAny())).captured;
    final request = captured.single as ReprovarTrativasDesvioRequest;
    expect(request.itens, hasLength(1));
    expect(request.itens.first.trativaId, 't-1');
    expect(request.itens.first.motivo, 'Faltou anexar o laudo');
  });

  testWidgets('aprovar todas chama o repositório com o comentário informado',
      (tester) async {
    final repo = MockDesvioRepository();
    when(() => repo.aprovar(any(), any())).thenAnswer((_) async {});

    await tester.pumpWidget(_wrapWithRepo(
      RevisarTratativasSection(
        d: _buildDesvio(),
        token: null,
        runAction: (action) => action(),
      ),
      repo,
    ));

    await tester.enterText(find.byType(TextField), 'Tudo certo, parabéns');
    await tester.tap(find.text('Aprovar Todas'));
    await tester.pumpAndSettle();

    final captured = verify(() => repo.aprovar('d-1', captureAny())).captured;
    final request = captured.single as AprovarDesvioRequest;
    expect(request.toJson()['comentario'], 'Tudo certo, parabéns');
  });
```

- [ ] **Step 2: Rodar os testes e confirmar que os 3 novos falham**

Run: `cd /home/mag/Documents/mobile/engseg-mobile && flutter test test/features/ocorrencias/widgets/revisar_tratativas_section_test.dart`
Expected: FAIL nos 3 novos testes — `repo.reprovar`/`repo.aprovar` nunca são
chamados e a mensagem de erro nunca aparece, porque `onPressed` ainda é `() {}`.

- [ ] **Step 3: Implementar `_confirmar` e ligar ao botão**

Em `lib/features/ocorrencias/widgets/revisar_tratativas_section.dart`, troque:

```dart
              onPressed: () {},
```

por:

```dart
              onPressed: _confirmar,
```

E adicione o método `_confirmar` à classe `_RevisarTratativasSectionState`
(após `_thumbFallback`):

```dart

  Future<void> _confirmar() async {
    if (_algumaMarcada) {
      final itens = <ItemReprovacao>[];
      for (final t in _pendentes) {
        if (_reprovarMarcado[t.id] != true) continue;
        final motivo = _motivoControllers[t.id]!.text.trim();
        if (motivo.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Preencha o motivo de todas as tratativas marcadas para reprovação.'),
            backgroundColor: ProtoColors.red,
          ));
          return;
        }
        itens.add(ItemReprovacao(trativaId: t.id, motivo: motivo));
      }
      await widget.runAction(() => ref
          .read(desvioRepositoryProvider)
          .reprovar(widget.d.id, ReprovarTrativasDesvioRequest(itens: itens)));
    } else {
      final comentario = _comentarioController.text.trim();
      await widget.runAction(() => ref.read(desvioRepositoryProvider).aprovar(
            widget.d.id,
            AprovarDesvioRequest(
                comentario: comentario.isEmpty ? null : comentario),
          ));
    }
  }
```

- [ ] **Step 4: Rodar os testes e confirmar que todos passam**

Run: `cd /home/mag/Documents/mobile/engseg-mobile && flutter test test/features/ocorrencias/widgets/revisar_tratativas_section_test.dart`
Expected: PASS (5 testes)

- [ ] **Step 5: Commit**

```bash
cd /home/mag/Documents/mobile/engseg-mobile
git add lib/features/ocorrencias/widgets/revisar_tratativas_section.dart test/features/ocorrencias/widgets/revisar_tratativas_section_test.dart
git commit -m "feat: confirmar revisão de tratativas chama aprovar/reprovar"
```

---

### Task 3: Integrar a seção em `desvio_detail_page.dart`

**Files:**
- Modify: `lib/features/ocorrencias/desvio_detail_page.dart`

- [ ] **Step 1: Importar o novo widget**

Em `lib/features/ocorrencias/desvio_detail_page.dart`, no bloco de imports
(próximo aos demais imports relativos), adicione:

```dart
import 'widgets/revisar_tratativas_section.dart';
```

- [ ] **Step 2: Substituir os botões Aprovar/Reprovar pela nova seção**

Localize em `_actions()`:

```dart
      case 'AGUARDANDO_APROVACAO':
        if (!isApprover) return [];
        return [
          _btn('Aprovar', Icons.check_circle_outline_rounded, ProtoColors.green,
              () => _run(() => ref.read(desvioRepositoryProvider).aprovar(
                  d.id, const AprovarDesvioRequest()))),
          const SizedBox(height: 10),
          _btn('Reprovar', Icons.cancel_outlined, ProtoColors.red, _openReprovar),
        ];
```

Substitua por:

```dart
      case 'AGUARDANDO_APROVACAO':
        if (!isApprover) return [];
        return [
          RevisarTratativasSection(d: d, token: _token, runAction: _run),
        ];
```

- [ ] **Step 3: Remover `_openReprovar()`**

Remova o método `_openReprovar()` inteiro (do `Future<void> _openReprovar() async {`
até o `}` que o fecha, logo antes do `}` final da classe `_BodyState`):

```dart
  Future<void> _openReprovar() async {
    final pendentes = d.tratativas
        .where((t) => t.rodada == d.rodadaAtual && t.status == 'PENDENTE')
        .toList();
    final motivos = {for (final t in pendentes) t.id: TextEditingController()};
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProtoColors.surface,
        title: const Text('Reprovar tratativas',
            style: TextStyle(color: ProtoColors.text)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: pendentes
                .map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.titulo,
                              style: const TextStyle(
                                  color: ProtoColors.text, fontSize: 13)),
                          TextField(
                            controller: motivos[t.id],
                            style: const TextStyle(color: ProtoColors.text),
                            decoration:
                                const InputDecoration(hintText: 'Motivo'),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reprovar')),
        ],
      ),
    );
    if (ok != true) return;
    final itens = pendentes
        .map((t) => ItemReprovacao(
            trativaId: t.id, motivo: motivos[t.id]!.text.trim()))
        .where((i) => i.motivo.isNotEmpty)
        .toList();
    for (final c in motivos.values) c.dispose();
    if (itens.isEmpty) return;
    await _run(() => ref
        .read(desvioRepositoryProvider)
        .reprovar(d.id, ReprovarTrativasDesvioRequest(itens: itens)));
  }
```

(deixe o `}` final da classe `_BodyState` no lugar — apenas o método é
removido).

- [ ] **Step 4: Rodar análise estática e a suíte de testes completa**

Run: `cd /home/mag/Documents/mobile/engseg-mobile && flutter analyze`
Expected: `No issues found!`

Run: `cd /home/mag/Documents/mobile/engseg-mobile && flutter test`
Expected: todos os testes passam (incluindo os 5 novos de
`revisar_tratativas_section_test.dart`).

- [ ] **Step 5: Commit**

```bash
cd /home/mag/Documents/mobile/engseg-mobile
git add lib/features/ocorrencias/desvio_detail_page.dart
git commit -m "refactor: usar RevisarTratativasSection na revisão de Desvio"
```
