# Histórico de Planos de Tratativa + toggle Aprovar/Reprovar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir a lista plana de tratativas em `DesvioDetailPage` por um histórico recolhível de "Planos" (um por rodada), sinalizando em vermelho o plano reprovado (motivo, quem reprovou, quando), e trocar o `Checkbox` "Reprovar" de `RevisarTratativasSection` por duas pílulas explícitas "Aprovar"/"Reprovar" por item.

**Architecture:** Extrai a lógica de agrupamento `d.tratativas` + `d.historico` em "Planos" para uma função pura e testável (`buildPlanos`) em um novo arquivo de modelo público (`model/plano_tratativa.dart`). A renderização do histórico vira um novo widget standalone `PlanosTratativaSection` (StatefulWidget com estado de expansão), que substitui `_tratativasSection`/`_tratativaCard`/`_thumbFallback` em `desvio_detail_page.dart`. `RevisarTratativasSection` troca `Map<String, bool> _reprovarMarcado` por `Map<String, bool?> _decisao` (null=neutro/true=reprovar/false=aprovar) e dois botões-pílula por item; a lógica de envio (`_confirmar`) não muda.

**Tech Stack:** Flutter/Dart, Riverpod, `flutter_test`, design system `ProtoColors`/`ProtoCard`/`ProtoPill` em `lib/shared/widgets/prototype_ui.dart`.

---

## Task 1: Modelo `Plano` + `buildPlanos`

**Files:**
- Create: `lib/features/ocorrencias/model/plano_tratativa.dart`
- Test: `test/features/ocorrencias/model/plano_tratativa_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/ocorrencias/model/plano_tratativa_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/features/ocorrencias/model/plano_tratativa.dart';
import 'package:engseg_mobile/features/ocorrencias/model/trativa_desvio.dart';

List<TrativaDesvio> _tratativas() => const [
      TrativaDesvio(
        id: 't-1',
        titulo: 'Instalação de guarda-corpo',
        descricao: 'Guarda-corpo instalado no setor',
        status: 'REPROVADO',
        motivoReprovacao: 'Faltou o anexo',
        numero: 1,
        rodada: 1,
      ),
      TrativaDesvio(
        id: 't-2',
        titulo: 'Sinalização da área',
        descricao: 'Placas fixadas',
        status: 'APROVADO',
        numero: 2,
        rodada: 1,
      ),
      TrativaDesvio(
        id: 't-3',
        titulo: 'Treinamento NR-35',
        descricao: 'Treinamento aplicado à equipe',
        status: 'PENDENTE',
        numero: 3,
        rodada: 2,
      ),
    ];

List<Map<String, dynamic>> _historico() => [
      {
        'tipo': 'TRATATIVA_SUBMETIDA',
        'usuarioNome': 'Tecnico X',
        'dataAcao': '2026-06-11T17:47:59',
      },
      {
        'tipo': 'REPROVADO',
        'usuarioNome': 'Gustavo França',
        'comentario': 'Tratativa 1: Faltou o anexo',
        'dataAcao': '2026-06-12T14:34:03',
      },
      {
        'tipo': 'TRATATIVA_SUBMETIDA',
        'usuarioNome': 'Tecnico X',
        'dataAcao': '2026-06-12T14:59:01',
      },
    ];

void main() {
  test('agrupa por rodada e casa submissão/resultado por índice', () {
    final planos = buildPlanos(_tratativas(), _historico());

    expect(planos, hasLength(2));

    final plano1 = planos[0];
    expect(plano1.rodada, 1);
    expect(plano1.tratativas.map((t) => t.numero), [1, 2]);
    expect(plano1.resultado, ResultadoPlano.reprovado);
    expect(plano1.dataSubmissao, '2026-06-11T17:47:59');
    expect(plano1.dataResultado, '2026-06-12T14:34:03');
    expect(plano1.revisorNome, 'Gustavo França');
    expect(plano1.comentario, 'Tratativa 1: Faltou o anexo');

    final plano2 = planos[1];
    expect(plano2.rodada, 2);
    expect(plano2.tratativas.map((t) => t.numero), [3]);
    expect(plano2.resultado, ResultadoPlano.emAnalise);
    expect(plano2.dataSubmissao, '2026-06-12T14:59:01');
    expect(plano2.dataResultado, isNull);
    expect(plano2.revisorNome, isNull);
  });

  test('sem historico, todas aprovadas resulta em plano aprovado', () {
    final planos = buildPlanos(
      const [
        TrativaDesvio(
          id: 't-1',
          titulo: 'Item',
          descricao: 'Desc',
          status: 'APROVADO',
          numero: 1,
          rodada: 1,
        ),
      ],
      [],
    );

    expect(planos, hasLength(1));
    expect(planos.single.resultado, ResultadoPlano.aprovado);
  });

  test('sem tratativas retorna lista vazia', () {
    expect(buildPlanos(const [], const []), isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/mag/Documents/mobile/engseg-mobile && flutter test test/features/ocorrencias/model/plano_tratativa_test.dart`
Expected: FAIL — `Error: Error when reading 'lib/features/ocorrencias/model/plano_tratativa.dart': No such file or directory` (ou erro de import não resolvido).

- [ ] **Step 3: Write the implementation**

Create `lib/features/ocorrencias/model/plano_tratativa.dart`:

```dart
import 'trativa_desvio.dart';

enum ResultadoPlano { reprovado, aprovado, emAnalise }

/// Agrupamento de [TrativaDesvio] por rodada ("Plano"), casado com as
/// entradas de submissão/resultado do histórico do Desvio.
class Plano {
  final int rodada;
  final List<TrativaDesvio> tratativas;
  final ResultadoPlano resultado;
  final String? dataSubmissao;
  final String? dataResultado;
  final String? revisorNome;
  final String? comentario;

  const Plano({
    required this.rodada,
    required this.tratativas,
    required this.resultado,
    this.dataSubmissao,
    this.dataResultado,
    this.revisorNome,
    this.comentario,
  });
}

List<Plano> buildPlanos(
  List<TrativaDesvio> tratativas,
  List<Map<String, dynamic>> historico,
) {
  final byRodada = <int, List<TrativaDesvio>>{};
  for (final t in tratativas) {
    byRodada.putIfAbsent(t.rodada, () => []).add(t);
  }

  final submissoes = <Map<String, dynamic>>[];
  final resultados = <Map<String, dynamic>>[];
  for (final h in historico) {
    final tipo = h['tipo'] as String?;
    if (tipo == 'TRATATIVA_SUBMETIDA') {
      submissoes.add(h);
    } else if (tipo == 'REPROVADO' || tipo == 'APROVADO') {
      resultados.add(h);
    }
  }

  final rodadas = byRodada.keys.toList()..sort();
  return [
    for (var i = 0; i < rodadas.length; i++)
      _buildPlano(
        rodadas[i],
        byRodada[rodadas[i]]!..sort((a, b) => a.numero.compareTo(b.numero)),
        i < submissoes.length ? submissoes[i] : null,
        i < resultados.length ? resultados[i] : null,
      ),
  ];
}

Plano _buildPlano(
  int rodada,
  List<TrativaDesvio> tratativas,
  Map<String, dynamic>? submissao,
  Map<String, dynamic>? resultadoHist,
) {
  final temReprovada = tratativas.any((t) => t.status == 'REPROVADO');
  final todosAprovados = tratativas.every((t) => t.status == 'APROVADO');
  final resultado = resultadoHist != null
      ? (resultadoHist['tipo'] == 'REPROVADO'
          ? ResultadoPlano.reprovado
          : ResultadoPlano.aprovado)
      : (temReprovada
          ? ResultadoPlano.reprovado
          : todosAprovados
              ? ResultadoPlano.aprovado
              : ResultadoPlano.emAnalise);

  return Plano(
    rodada: rodada,
    tratativas: tratativas,
    resultado: resultado,
    dataSubmissao: submissao?['dataAcao'] as String?,
    dataResultado: resultadoHist?['dataAcao'] as String?,
    revisorNome: resultadoHist?['usuarioNome'] as String?,
    comentario: resultadoHist?['comentario'] as String?,
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/mag/Documents/mobile/engseg-mobile && flutter test test/features/ocorrencias/model/plano_tratativa_test.dart`
Expected: PASS (3 testes).

- [ ] **Step 5: Commit**

```bash
cd /home/mag/Documents/mobile/engseg-mobile && git add lib/features/ocorrencias/model/plano_tratativa.dart test/features/ocorrencias/model/plano_tratativa_test.dart && git commit -m "feat: agrupa tratativas em Planos por rodada com buildPlanos"
```

---

## Task 2: Widget `PlanosTratativaSection`

**Files:**
- Create: `lib/features/ocorrencias/widgets/planos_tratativa_section.dart`
- Test: `test/features/ocorrencias/widgets/planos_tratativa_section_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/ocorrencias/widgets/planos_tratativa_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/features/ocorrencias/model/desvio_detail.dart';
import 'package:engseg_mobile/features/ocorrencias/model/trativa_desvio.dart';
import 'package:engseg_mobile/features/ocorrencias/widgets/planos_tratativa_section.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

DesvioDetail _buildDesvio() => const DesvioDetail(
      id: 'd-1',
      titulo: 'Desvio de teste',
      status: 'AGUARDANDO_APROVACAO',
      tratativas: [
        TrativaDesvio(
          id: 't-1',
          titulo: 'Instalação de guarda-corpo',
          descricao: 'Guarda-corpo instalado no setor',
          status: 'REPROVADO',
          motivoReprovacao: 'Faltou o anexo',
          numero: 1,
          rodada: 1,
        ),
        TrativaDesvio(
          id: 't-2',
          titulo: 'Sinalização da área',
          descricao: 'Placas fixadas',
          status: 'APROVADO',
          numero: 2,
          rodada: 1,
        ),
        TrativaDesvio(
          id: 't-3',
          titulo: 'Treinamento NR-35',
          descricao: 'Treinamento aplicado à equipe',
          status: 'PENDENTE',
          numero: 3,
          rodada: 2,
        ),
      ],
      historico: [
        {
          'tipo': 'TRATATIVA_SUBMETIDA',
          'usuarioNome': 'Tecnico X',
          'dataAcao': '2026-06-11T17:47:59',
        },
        {
          'tipo': 'REPROVADO',
          'usuarioNome': 'Gustavo França',
          'comentario': 'Tratativa 1: Faltou o anexo',
          'dataAcao': '2026-06-12T14:34:03',
        },
        {
          'tipo': 'TRATATIVA_SUBMETIDA',
          'usuarioNome': 'Tecnico X',
          'dataAcao': '2026-06-12T14:59:01',
        },
      ],
    );

void main() {
  testWidgets('Plano reprovado vem recolhido e o plano atual vem expandido',
      (tester) async {
    await tester
        .pumpWidget(_wrap(PlanosTratativaSection(d: _buildDesvio(), token: null)));

    expect(find.text('Plano 1'), findsOneWidget);
    expect(find.text('Plano 2'), findsOneWidget);
    expect(find.text('Reprovado'), findsOneWidget);
    expect(find.text('Em análise'), findsOneWidget);

    // Plano 1 (reprovado) recolhido: motivo não visível, mas aviso de quem
    // reprovou sim, mesmo recolhido.
    expect(find.text('Motivo: Faltou o anexo'), findsNothing);
    expect(find.textContaining('Reprovado por Gustavo França'), findsOneWidget);

    // Plano 2 (rodada atual) expandido por padrão
    expect(find.text('Treinamento NR-35'), findsOneWidget);
  });

  testWidgets('tocar no cabeçalho do plano reprovado expande o conteúdo',
      (tester) async {
    await tester
        .pumpWidget(_wrap(PlanosTratativaSection(d: _buildDesvio(), token: null)));

    await tester.tap(find.text('Plano 1'));
    await tester.pumpAndSettle();

    expect(find.text('Motivo: Faltou o anexo'), findsOneWidget);
    expect(find.text('Sinalização da área'), findsOneWidget);
  });

  testWidgets('sem tratativas mostra mensagem vazia', (tester) async {
    await tester.pumpWidget(_wrap(const PlanosTratativaSection(
      d: DesvioDetail(id: 'd-2', titulo: 'X', status: 'ABERTO'),
      token: null,
    )));

    expect(find.text('Nenhuma tratativa ainda'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/mag/Documents/mobile/engseg-mobile && flutter test test/features/ocorrencias/widgets/planos_tratativa_section_test.dart`
Expected: FAIL — import não resolvido / `PlanosTratativaSection` não definido.

- [ ] **Step 3: Write the implementation**

Create `lib/features/ocorrencias/widgets/planos_tratativa_section.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../shared/widgets/prototype_ui.dart';
import '../model/desvio_detail.dart';
import '../model/plano_tratativa.dart';
import '../model/trativa_desvio.dart';

/// Histórico de "Planos" de tratativa de um Desvio: cada rodada vira um card
/// recolhível, com o resultado (Reprovado/Aprovado/Em análise) sinalizado por
/// uma faixa colorida à esquerda. O plano da rodada atual vem expandido por
/// padrão; planos reprovados anteriores vêm recolhidos, mas sinalizam em
/// vermelho quem reprovou e quando.
class PlanosTratativaSection extends StatefulWidget {
  final DesvioDetail d;
  final String? token;

  const PlanosTratativaSection({super.key, required this.d, required this.token});

  @override
  State<PlanosTratativaSection> createState() => _PlanosTratativaSectionState();
}

class _PlanosTratativaSectionState extends State<PlanosTratativaSection> {
  late Set<int> _expandidos;

  @override
  void initState() {
    super.initState();
    final planos = buildPlanos(widget.d.tratativas, widget.d.historico);
    _expandidos = {if (planos.isNotEmpty) planos.last.rodada};
  }

  @override
  Widget build(BuildContext context) {
    final planos = buildPlanos(widget.d.tratativas, widget.d.historico);
    if (planos.isEmpty) {
      return ProtoCard(
        child: Row(children: [
          const Icon(Icons.inbox_outlined, color: ProtoColors.muted, size: 18),
          const SizedBox(width: 10),
          const Text('Nenhuma tratativa ainda',
              style: TextStyle(color: ProtoColors.muted, fontSize: 13)),
        ]),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PLANOS DE TRATATIVA',
          style: TextStyle(
              color: ProtoColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: .5),
        ),
        const SizedBox(height: 8),
        for (final plano in planos) ...[
          _planoCard(plano),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _planoCard(Plano plano) {
    final (accent, label) = switch (plano.resultado) {
      ResultadoPlano.reprovado => (ProtoColors.red, 'Reprovado'),
      ResultadoPlano.aprovado => (ProtoColors.green, 'Aprovado'),
      ResultadoPlano.emAnalise => (ProtoColors.blue, 'Em análise'),
    };
    final pillFg =
        plano.resultado == ResultadoPlano.emAnalise ? ProtoColors.bg : Colors.white;
    final expandido = _expandidos.contains(plano.rodada);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: ProtoColors.surface,
          border: Border.all(color: ProtoColors.border),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accent),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => setState(() {
                        if (expandido) {
                          _expandidos.remove(plano.rodada);
                        } else {
                          _expandidos.add(plano.rodada);
                        }
                      }),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Text('Plano ${plano.rodada}',
                                          style: const TextStyle(
                                              color: ProtoColors.text,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900)),
                                      if (plano.dataSubmissao != null)
                                        Text(_fmtDateTime(plano.dataSubmissao),
                                            style: const TextStyle(
                                                color: ProtoColors.muted,
                                                fontSize: 11)),
                                      ProtoPill(label: label, bg: accent, fg: pillFg),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  expandido ? Icons.expand_less : Icons.expand_more,
                                  color: ProtoColors.muted,
                                  size: 20,
                                ),
                              ],
                            ),
                            if (!expandido &&
                                plano.resultado == ResultadoPlano.reprovado &&
                                plano.revisorNome != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Reprovado por ${plano.revisorNome} • ${_fmtDateTime(plano.dataResultado)}',
                                style: const TextStyle(
                                    color: ProtoColors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (expandido)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (plano.resultado == ResultadoPlano.aprovado &&
                                (plano.comentario?.isNotEmpty ?? false))
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0B3A1C),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('Comentário: ${plano.comentario}',
                                    style: const TextStyle(
                                        color: ProtoColors.green, fontSize: 12)),
                              ),
                            for (final t in plano.tratativas) _tratativaItemCard(t),
                            if (plano.revisorNome != null)
                              Text(
                                '${plano.resultado == ResultadoPlano.reprovado ? 'Reprovado' : 'Aprovado'} por ${plano.revisorNome} • ${_fmtDateTime(plano.dataResultado)}',
                                style: TextStyle(
                                    color: plano.resultado == ResultadoPlano.reprovado
                                        ? ProtoColors.red
                                        : ProtoColors.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tratativaItemCard(TrativaDesvio t) {
    final (cardBg, cardBorder, pillFg, label) = switch (t.status) {
      'APROVADO' => (const Color(0xFF0B3A1C), ProtoColors.green, ProtoColors.green, 'Aprovada'),
      'REPROVADO' => (const Color(0xFF4A1017), ProtoColors.red, ProtoColors.red, 'Reprovada'),
      _ => (ProtoColors.surface2, ProtoColors.border, ProtoColors.blue, 'Em análise'),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ProtoCard(
        color: cardBg,
        border: Border.all(color: cardBorder),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(t.titulo,
                    style: const TextStyle(
                        color: ProtoColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ),
              ProtoPill(label: label, bg: cardBg, fg: pillFg),
            ]),
            const SizedBox(height: 6),
            Text(t.descricao,
                style: const TextStyle(color: ProtoColors.muted, fontSize: 13)),
            if (t.motivoReprovacao != null && t.motivoReprovacao!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ProtoColors.red.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Motivo: ${t.motivoReprovacao}',
                    style: const TextStyle(
                        color: ProtoColors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
            if (t.evidencias.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: t.evidencias.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final url = t.evidencias[i].url;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: url != null
                          ? Image(
                              image: NetworkImage(url,
                                  headers: widget.token != null
                                      ? {'Authorization': 'Bearer ${widget.token}'}
                                      : {}),
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _thumbFallback(),
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
    );
  }

  Widget _thumbFallback() => Container(
        width: 64,
        height: 64,
        color: ProtoColors.surface2,
        child: const Icon(Icons.image_outlined, color: ProtoColors.muted),
      );
}

String _fmtDateTime(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    final utc = DateTime.parse(iso.contains('Z') ? iso : '${iso}Z');
    final br = utc.subtract(const Duration(hours: 3));
    return '${br.day.toString().padLeft(2, '0')}/${br.month.toString().padLeft(2, '0')}/${br.year} '
        '${br.hour.toString().padLeft(2, '0')}:${br.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/mag/Documents/mobile/engseg-mobile && flutter test test/features/ocorrencias/widgets/planos_tratativa_section_test.dart`
Expected: PASS (3 testes).

- [ ] **Step 5: Commit**

```bash
cd /home/mag/Documents/mobile/engseg-mobile && git add lib/features/ocorrencias/widgets/planos_tratativa_section.dart test/features/ocorrencias/widgets/planos_tratativa_section_test.dart && git commit -m "feat: novo PlanosTratativaSection com historico recolhivel de planos"
```

---

## Task 3: Integrar `PlanosTratativaSection` em `desvio_detail_page.dart`

**Files:**
- Modify: `lib/features/ocorrencias/desvio_detail_page.dart`

- [ ] **Step 1: Adicionar o import do novo widget**

Em `lib/features/ocorrencias/desvio_detail_page.dart`, na lista de imports (linhas 15-21), substitua:

```dart
import 'model/desvio_action_requests.dart';
import 'model/desvio_detail.dart';
import 'model/evidencia_metadata.dart';
import 'model/trativa_desvio.dart';
import 'repository/desvio_repository_impl.dart';
import 'repository/evidencia_repository_impl.dart';
import 'widgets/revisar_tratativas_section.dart';
```

por:

```dart
import 'model/desvio_action_requests.dart';
import 'model/desvio_detail.dart';
import 'model/evidencia_metadata.dart';
import 'repository/desvio_repository_impl.dart';
import 'repository/evidencia_repository_impl.dart';
import 'widgets/planos_tratativa_section.dart';
import 'widgets/revisar_tratativas_section.dart';
```

(O import de `model/trativa_desvio.dart` é removido porque, após o Step 3, `TrativaDesvio` deixa de ser referenciado diretamente neste arquivo — só era usado dentro de `_tratativasSection`/`_tratativaCard`, que serão removidos.)

- [ ] **Step 2: Trocar a chamada de `_tratativasSection()` pelo novo widget**

Por volta da linha 393, substitua:

```dart
              // ── Tratativas ─────────────────────────────────────
              _tratativasSection(),
```

por:

```dart
              // ── Tratativas ─────────────────────────────────────
              PlanosTratativaSection(d: d, token: _token),
```

- [ ] **Step 3: Remover `_tratativasSection`, `_tratativaCard` e `_thumbFallback`**

Remova o bloco completo (atualmente nas linhas 470-579), do início de `_tratativasSection` até o final de `_thumbFallback` inclusive, incluindo a linha em branco que o separa de `_actions`:

```dart
  Widget _tratativasSection() {
    if (d.tratativas.isEmpty) {
      return ProtoCard(
        child: Row(children: [
          const Icon(Icons.inbox_outlined, color: ProtoColors.muted, size: 18),
          const SizedBox(width: 10),
          const Text('Nenhuma tratativa ainda',
              style: TextStyle(color: ProtoColors.muted, fontSize: 13)),
        ]),
      );
    }
    final byRodada = <int, List<TrativaDesvio>>{};
    for (final t in d.tratativas) {
      byRodada.putIfAbsent(t.rodada, () => []).add(t);
    }
    final rodadas = byRodada.keys.toList()..sort((a, b) => b.compareTo(a));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Tratativas'),
        const SizedBox(height: 8),
        ...rodadas.map((r) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('Rodada $r',
                      style: const TextStyle(
                          color: ProtoColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w900)),
                ),
                ...byRodada[r]!.map(_tratativaCard),
                const SizedBox(height: 8),
              ],
            )),
      ],
    );
  }

  Widget _tratativaCard(TrativaDesvio t) {
    final (bg, fg) = switch (t.status) {
      'APROVADO' => (const Color(0xFF0B3A1C), ProtoColors.green),
      'REPROVADO' => (const Color(0xFF4A1017), ProtoColors.red),
      _ => (ProtoColors.surface2, ProtoColors.blue),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ProtoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(t.titulo,
                    style: const TextStyle(
                        color: ProtoColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ),
              ProtoPill(label: t.status, bg: bg, fg: fg),
            ]),
            const SizedBox(height: 6),
            Text(t.descricao,
                style: const TextStyle(
                    color: ProtoColors.muted, fontSize: 13)),
            if (t.motivoReprovacao != null && t.motivoReprovacao!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Motivo: ${t.motivoReprovacao}',
                  style: const TextStyle(color: ProtoColors.red, fontSize: 12)),
            ],
            if (t.evidencias.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: t.evidencias.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final url = t.evidencias[i].url;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: url != null
                          ? Image(
                              image: NetworkImage(url,
                                  headers: _token != null
                                      ? {'Authorization': 'Bearer $_token'}
                                      : {}),
                              width: 64, height: 64, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _thumbFallback())
                          : _thumbFallback(),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _thumbFallback() => Container(
        width: 64,
        height: 64,
        color: ProtoColors.surface2,
        child: const Icon(Icons.image_outlined, color: ProtoColors.muted),
      );

```

Resultado: o que sobra antes de `_actions` é `_sectionLabel`/`_row2`/`_rowFull`/`_cell`/`_responsavelCell` (linhas 409-468 originais), seguido diretamente por `List<Widget> _actions({...`.

`_sectionLabel` continua em uso (linhas 351 e 372), então permanece no arquivo.

- [ ] **Step 4: Rodar análise estática**

Run: `cd /home/mag/Documents/mobile/engseg-mobile && flutter analyze lib/features/ocorrencias/desvio_detail_page.dart`
Expected: `No issues found!` (sem warnings de import não usado ou método não definido).

- [ ] **Step 5: Rodar os testes de modelo da página de detalhe**

Run: `cd /home/mag/Documents/mobile/engseg-mobile && flutter test test/features/ocorrencias/desvio_detail_test.dart`
Expected: PASS (testes de `DesvioDetail.fromJson` não dependem da UI, devem continuar passando).

- [ ] **Step 6: Commit**

```bash
cd /home/mag/Documents/mobile/engseg-mobile && git add lib/features/ocorrencias/desvio_detail_page.dart && git commit -m "refactor: usa PlanosTratativaSection na pagina de detalhe do desvio"
```

---

## Task 4: Pílulas "Aprovar"/"Reprovar" em `RevisarTratativasSection`

**Files:**
- Modify: `lib/features/ocorrencias/widgets/revisar_tratativas_section.dart`
- Modify: `test/features/ocorrencias/widgets/revisar_tratativas_section_test.dart`

- [ ] **Step 1: Atualizar os testes existentes para as pílulas**

Em `test/features/ocorrencias/widgets/revisar_tratativas_section_test.dart`, faça as seguintes trocas:

1. No teste `'estado inicial mostra comentário opcional e botão Aprovar Todas'`, substitua:

```dart
    expect(find.byType(Checkbox), findsNWidgets(2));
```

por:

```dart
    expect(find.text('Aprovar'), findsNWidgets(2));
    expect(find.text('Reprovar'), findsNWidgets(2));
```

2. Nos testes `'marcar reprovar exibe motivo obrigatório e muda o botão'`,
   `'reprovar com motivo vazio mostra erro e não chama o repositório'` e
   `'reprovar com motivo preenchido chama o repositório com o item marcado'`,
   substitua (em cada um, há uma ocorrência):

```dart
    await tester.tap(find.byType(Checkbox).first);
```

por:

```dart
    await tester.tap(find.text('Reprovar').first);
```

3. Adicione um novo teste, ao final do `main()`, antes do `}` final, depois do teste `'aprovar todas chama o repositório com o comentário informado'`:

```dart

  testWidgets(
      'alternar de Reprovar para Aprovar no mesmo item volta ao estado neutro',
      (tester) async {
    await tester.pumpWidget(_wrap(RevisarTratativasSection(
      d: _buildDesvio(),
      token: null,
      runAction: (action) => action(),
    )));

    await tester.tap(find.text('Reprovar').first);
    await tester.pump();

    expect(find.text('Motivo da reprovação (obrigatório)'), findsOneWidget);
    expect(find.text('Reprovar 1 tratativa(s)'), findsOneWidget);

    await tester.tap(find.text('Aprovar').first);
    await tester.pump();

    expect(find.text('Motivo da reprovação (obrigatório)'), findsNothing);
    expect(find.text('Aprovar Todas'), findsOneWidget);
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /home/mag/Documents/mobile/engseg-mobile && flutter test test/features/ocorrencias/widgets/revisar_tratativas_section_test.dart`
Expected: FAIL — `find.text('Aprovar')`/`find.text('Reprovar')` não encontram pílulas (ainda há `Checkbox` + texto "Reprovar" único, não duas pílulas "Aprovar"/"Reprovar" por item).

- [ ] **Step 3: Implementar as pílulas em `revisar_tratativas_section.dart`**

Substitua a declaração de estado, `initState`, `_algumaMarcada` e o cálculo de `marcadas` (linhas 31-65 do arquivo atual):

```dart
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
```

por:

```dart
class _RevisarTratativasSectionState
    extends ConsumerState<RevisarTratativasSection> {
  late final List<TrativaDesvio> _pendentes;
  late final Map<String, bool?> _decisao;
  late final Map<String, TextEditingController> _motivoControllers;
  late final TextEditingController _comentarioController;

  @override
  void initState() {
    super.initState();
    _pendentes = widget.d.tratativas
        .where((t) =>
            t.rodada == widget.d.rodadaAtual && t.status == 'PENDENTE')
        .toList();
    _decisao = {for (final t in _pendentes) t.id: null};
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

  bool get _algumaMarcada => _decisao.values.any((v) => v == true);

  @override
  Widget build(BuildContext context) {
    final marcadas = _decisao.values.where((v) => v == true).length;
```

- [ ] **Step 4: Substituir `_itemCard` e adicionar `_decisaoPill`**

Substitua o método `_itemCard` inteiro (linhas 146-273 do arquivo atual, do `Widget _itemCard(TrativaDesvio t) {` até o `}` que o fecha, antes de `_thumbFallback`):

```dart
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
```

por:

```dart
  Widget _itemCard(TrativaDesvio t) {
    final decisao = _decisao[t.id];
    final borderColor = switch (decisao) {
      true => ProtoColors.red,
      false => ProtoColors.green,
      null => ProtoColors.border,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ProtoCard(
        border: Border.all(color: borderColor),
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _decisaoPill(
                      label: 'Aprovar',
                      color: ProtoColors.green,
                      selectedFg: ProtoColors.bg,
                      selecionado: decisao == false,
                      onTap: () => setState(
                          () => _decisao[t.id] = decisao == false ? null : false),
                    ),
                    const SizedBox(width: 6),
                    _decisaoPill(
                      label: 'Reprovar',
                      color: ProtoColors.red,
                      selectedFg: Colors.white,
                      selecionado: decisao == true,
                      onTap: () => setState(
                          () => _decisao[t.id] = decisao == true ? null : true),
                    ),
                  ],
                ),
              ],
            ),
            if (decisao == true) ...[
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

  Widget _decisaoPill({
    required String label,
    required Color color,
    required Color selectedFg,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selecionado ? color : Colors.transparent,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selecionado ? selectedFg : color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
```

- [ ] **Step 5: Atualizar `_confirmar()`**

Substitua:

```dart
        if (_reprovarMarcado[t.id] != true) continue;
```

por:

```dart
        if (_decisao[t.id] != true) continue;
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd /home/mag/Documents/mobile/engseg-mobile && flutter test test/features/ocorrencias/widgets/revisar_tratativas_section_test.dart`
Expected: PASS (6 testes).

- [ ] **Step 7: Run analyze**

Run: `cd /home/mag/Documents/mobile/engseg-mobile && flutter analyze lib/features/ocorrencias/widgets/revisar_tratativas_section.dart`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
cd /home/mag/Documents/mobile/engseg-mobile && git add lib/features/ocorrencias/widgets/revisar_tratativas_section.dart test/features/ocorrencias/widgets/revisar_tratativas_section_test.dart && git commit -m "feat: troca checkbox Reprovar por pilulas Aprovar/Reprovar"
```

---

## Task 5: Suíte completa

**Files:** (nenhum, apenas verificação)

- [ ] **Step 1: Rodar toda a suíte de testes de ocorrências**

Run: `cd /home/mag/Documents/mobile/engseg-mobile && flutter test test/features/ocorrencias/`
Expected: PASS — todos os testes (novos e existentes) passam.

- [ ] **Step 2: Rodar analyze no projeto inteiro**

Run: `cd /home/mag/Documents/mobile/engseg-mobile && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: Teste manual no app**

Abrir um Desvio em `AGUARDANDO_TRATATIVA`/`AGUARDANDO_APROVACAO`/`CONCLUIDO` com pelo menos 2 rodadas (uma reprovada) e verificar visualmente:
- "Planos de Tratativa" mostra "Plano 1" recolhido com borda vermelha e "Reprovado por ... • ...";
- tocar no cabeçalho expande/recolhe;
- "Plano 2" (atual) vem expandido;
- na tela "Revisar Tratativas", cada item mostra pílulas "Aprovar"/"Reprovar"; marcar "Reprovar" exibe o campo de motivo e tingue a borda vermelha; marcar "Aprovar" tingue verde; tocar de novo na pílula selecionada volta ao neutro.

---

## Self-Review

- **Cobertura do spec:** Seção 1 (agrupamento em Planos) → Task 1. Seção 2 (`_tratativasSection` → histórico de Planos, recolher/expandir, sinalização vermelha recolhida) → Task 2. Seção 3 (`_tratativaItemCard` tingido por status) → Task 2 (`_tratativaItemCard`). Seção 4 (estado de expansão, último plano expandido por padrão) → Task 2 (`_expandidos` em `initState`). Seção 5 (pílulas Aprovar/Reprovar, `_decisao`) → Task 4. Testes descritos na spec → Tasks 1, 2 e 4.
- **Placeholders:** nenhum `TODO`/`TBD`; todo passo de código tem o código completo.
- **Consistência de tipos:** `Plano`/`ResultadoPlano`/`buildPlanos` (Task 1) são usados com a mesma assinatura em `PlanosTratativaSection` (Task 2). `Map<String, bool?> _decisao` é declarado e usado consistentemente em Task 4 (`initState`, `_algumaMarcada`, `_itemCard`, `_confirmar`). `PlanosTratativaSection({d, token})` (Task 2) é chamado com os mesmos nomes em Task 3.
