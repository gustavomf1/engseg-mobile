# Mobile NC & Desvio Flows Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add photo-first creation of NC and Desvio plus the complete Desvio tratativa flow (list, detail, abrir/adicionar/submeter/aprovar/reprovar) to the EngSeg Flutter app.

**Architecture:** Feature-first under `lib/features/ocorrencias`. Riverpod providers wrap repositories that talk to the existing Spring backend via the shared `dioProvider`. Camera handoff (`/camera?tipo=` → `/wizard/:tipo` with `extra`) and the FAB bottom-sheet already exist; we fill in the empty `WizardPage`, add a Desvio list/detail, and extend the Desvio repository. No backend changes.

**Tech Stack:** Flutter, Riverpod (`flutter_riverpod`), GoRouter, Dio, `image_picker`, `geolocator`; tests with `flutter_test` + `mocktail`. UI uses the `prototype_ui.dart` design system (`ProtoColors`, `ProtoCard`, `ProtoPill`, `ProtoSectionTitle`, `ProtoIconButton`).

---

## Backend facts (verified against engseg-api)

- **Status Desvio:** `ABERTO → AGUARDANDO_TRATATIVA → AGUARDANDO_APROVACAO → CONCLUIDO`; reprovar reopens a new round.
- **Endpoints Desvio:** `POST /api/desvios`, `GET /api/desvios`, `GET /api/desvios/{id}`, `POST /api/desvios/{id}/abrir-tratativa`, `POST /api/desvios/{id}/tratativas` (`AdicionarTrativaRequest`), `DELETE /api/desvios/{id}/tratativas/{trativaId}`, `POST /api/desvios/{id}/submeter-tratativa` (`SubmeterTrativaDesvioRequest`), `POST /api/desvios/{id}/aprovar` (`AprovarDesvioRequest`), `POST /api/desvios/{id}/reprovar` (`ReprovarTrativasDesvioRequest`).
- **`DesvioResponse`** fields (JSON keys): `id, estabelecimentoId, estabelecimentoNome, titulo, localizacaoId, localizacaoNome, descricao, dataRegistro, tecnicoNome, usuarioCriacaoNome, usuarioCriacaoEmail, orientacaoRealizada, regraDeOuro, status, responsavelDesvioId, responsavelDesvioNome, responsavelTratativaId, responsavelTrivaNome?`. **Important:** the id key is `responsavelTratativaId`; the name key is **`responsavelTrativaNome`** (single inner "a"). Lists: `historico` (`HistoricoDesvioResponse`), `tratativas` (`TrativaDesvioResponse`). The occurrence photos are **not** in `DesvioResponse` — fetch them via `GET /api/evidencias/desvio/{id}?tipo=OCORRENCIA`.
- **`TrativaDesvioResponse`** JSON keys: `id, titulo, descricao, evidencias[{id,nome,url}], status (PENDENTE|APROVADO|REPROVADO), motivoReprovacao, numero, rodada, dtCriacao`.
- **`AdicionarTrativaRequest`** requires `titulo`, `descricao`, and a **non-empty** `evidenciaIds` list. So a tratativa MUST carry ≥1 uploaded evidence.
- **`ReprovarTrativasDesvioRequest`** = `{ itens: [{ trativaId, motivo }], emailsManuais }` — per-tratativa motivo.
- **Evidence upload:** `POST /api/evidencias/desvio/{id}` (multipart `file`, optional `tipo` default `OCORRENCIA`, `latitude`, `longitude`, `capturedAt`, `origem`, `cidade`). For tratativa photos use `tipo=TRATATIVA`. **Backend gate: desvio upload is restricted to TECNICO/ENGENHEIRO** (not EXTERNO). NC upload allows EXTERNO too.
- **`NaoConformidadeRequest`** JSON keys: `estabelecimentoId, titulo, localizacaoId, descricao (required), severidade (1-5), probabilidade (1-4), responsavelTrativaId, responsavelNcId, regraDeOuro, normaIds, reincidencia, ncAnteriorId, emailsManuais, emailsPadraoExcluidos`.
- **Default emails:** `GET /api/emails-padrao?estabelecimentoId={id}&empresaId={id}` → `[{id, email, descricao, empresaId, ...}]`. **VERIFY:** which empresa id the web sends — assume `workspace.empresa.id`; if it 404s/empties, the email editor degrades to manual-only.

## Existing code we build on (do not recreate)

- `lib/shared/widgets/engseg_shell.dart` — FAB + bottom sheet already routes to `/camera?tipo=nc` and `/camera?tipo=desvio` (lowercase tipo).
- `lib/features/capture/camera_page.dart` — already navigates `context.go('/wizard/${tipo}', extra: {fotoPath, latitude, longitude, capturedAt(ms), cidade})` and `captureProvider` (NotifierProvider<…, List<XFile>>) holds up to 10 photos.
- `lib/core/network/dio_client.dart` — `dioProvider` (JWT interceptor). `baseUrl` already set; paths include `/api/...`.
- `lib/features/auth/provider/auth_provider.dart` — `authProvider` (`LoginResponse?` with `id`, `perfil`, `isAdmin`), `workspaceProvider` (`WorkspaceState?` with `.estabelecimento`, `.empresa`, `.empresaFilha`).
- `lib/features/ocorrencias/repository/support_repository_impl.dart` — providers `usuariosProvider(estabId)`, `localizacoesProvider(estabId)`, `normasProvider`, `estabelecimentosProvider`.
- `lib/features/ocorrencias/repository/desvio_repository_impl.dart` — `desvioRepositoryProvider`, `desvioListProvider(estabId)` already exist.
- Status maps `statusLabel` / `statusTone` in `lib/shared/data/mock_data.dart`.

## Testing approach

The repo tests models/repos with `flutter_test` + `mocktail` (`MockDio`); there are no widget tests. Follow that: **TDD (unit) for models, request DTOs, and repository methods**; UI pages are validated with `flutter analyze` + manual device test on the Redmi Note 7 (`flutter run -d f868b62`). Run all unit tests with `flutter test`.

---

## Phase A — Data models & request DTOs

### Task 1: Extend `CriarNcRequest` and `CriarDesvioRequest`

**Files:**
- Modify: `lib/features/ocorrencias/model/criar_nc_request.dart`
- Modify: `lib/features/ocorrencias/model/criar_desvio_request.dart`
- Test: `test/features/ocorrencias/criar_request_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/ocorrencias/criar_request_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/features/ocorrencias/model/criar_nc_request.dart';
import 'package:engseg_mobile/features/ocorrencias/model/criar_desvio_request.dart';

void main() {
  test('CriarNcRequest serializes new optional fields when present', () {
    final json = const CriarNcRequest(
      estabelecimentoId: 'est-1',
      titulo: 'T',
      descricao: 'D',
      severidade: 3,
      probabilidade: 2,
      localizacaoId: 'loc-1',
      responsavelNcId: 'u-nc',
      responsavelTrativaId: 'u-tr',
      normaIds: ['n1'],
    ).toJson();
    expect(json['localizacaoId'], 'loc-1');
    expect(json['responsavelNcId'], 'u-nc');
    expect(json['responsavelTrativaId'], 'u-tr');
    expect(json['severidade'], 3);
  });

  test('CriarNcRequest omits null optionals', () {
    final json = const CriarNcRequest(
      estabelecimentoId: 'est-1', titulo: 'T', descricao: 'D',
      severidade: 1, probabilidade: 1,
    ).toJson();
    expect(json.containsKey('localizacaoId'), false);
    expect(json.containsKey('responsavelNcId'), false);
  });

  test('CriarDesvioRequest serializes localizacaoId when present', () {
    final json = const CriarDesvioRequest(
      estabelecimentoId: 'est-1', titulo: 'T', localizacaoId: 'loc-9',
    ).toJson();
    expect(json['localizacaoId'], 'loc-9');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/ocorrencias/criar_request_test.dart`
Expected: FAIL — `CriarNcRequest` has no `localizacaoId`/`responsavelNcId`/`responsavelTrativaId` params.

- [ ] **Step 3: Add fields to `CriarNcRequest`**

Replace the whole file `lib/features/ocorrencias/model/criar_nc_request.dart` with:

```dart
class CriarNcRequest {
  final String estabelecimentoId;
  final String titulo;
  final String? descricao;
  final int severidade;
  final int probabilidade;
  final bool regraDeOuro;
  final bool reincidencia;
  final String? localizacaoId;
  final String? responsavelNcId;
  final String? responsavelTrativaId;
  final List<String> normaIds;
  final List<String> emailsManuais;
  final List<String> emailsPadraoExcluidos;

  const CriarNcRequest({
    required this.estabelecimentoId,
    required this.titulo,
    this.descricao,
    required this.severidade,
    required this.probabilidade,
    this.regraDeOuro = false,
    this.reincidencia = false,
    this.localizacaoId,
    this.responsavelNcId,
    this.responsavelTrativaId,
    this.normaIds = const [],
    this.emailsManuais = const [],
    this.emailsPadraoExcluidos = const [],
  });

  Map<String, dynamic> toJson() => {
        'estabelecimentoId': estabelecimentoId,
        'titulo': titulo,
        if (descricao != null) 'descricao': descricao,
        'severidade': severidade,
        'probabilidade': probabilidade,
        'regraDeOuro': regraDeOuro,
        'reincidencia': reincidencia,
        if (localizacaoId != null) 'localizacaoId': localizacaoId,
        if (responsavelNcId != null) 'responsavelNcId': responsavelNcId,
        if (responsavelTrativaId != null) 'responsavelTrativaId': responsavelTrativaId,
        'normaIds': normaIds,
        'emailsManuais': emailsManuais,
        'emailsPadraoExcluidos': emailsPadraoExcluidos,
      };
}
```

- [ ] **Step 4: Add `localizacaoId` to `CriarDesvioRequest`**

In `lib/features/ocorrencias/model/criar_desvio_request.dart` add the field `final String? localizacaoId;` (after `titulo`), add `this.localizacaoId,` to the constructor, and add `if (localizacaoId != null) 'localizacaoId': localizacaoId,` to `toJson()` (after `titulo`).

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/ocorrencias/criar_request_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/features/ocorrencias/model/criar_nc_request.dart lib/features/ocorrencias/model/criar_desvio_request.dart test/features/ocorrencias/criar_request_test.dart
git commit -m "feat(mobile): add responsaveis/localizacao to criar NC and localizacao to criar Desvio"
```

---

### Task 2: Desvio action request DTOs

**Files:**
- Create: `lib/features/ocorrencias/model/desvio_action_requests.dart`
- Test: `test/features/ocorrencias/desvio_action_requests_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/ocorrencias/desvio_action_requests_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/features/ocorrencias/model/desvio_action_requests.dart';

void main() {
  test('AdicionarTrativaRequest serializes', () {
    final j = const AdicionarTrativaRequest(
      titulo: 'T', descricao: 'D', evidenciaIds: ['e1', 'e2'],
    ).toJson();
    expect(j['titulo'], 'T');
    expect(j['evidenciaIds'], ['e1', 'e2']);
  });

  test('ReprovarTrativasDesvioRequest serializes itens', () {
    final j = const ReprovarTrativasDesvioRequest(
      itens: [ItemReprovacao(trativaId: 't1', motivo: 'm')],
      emailsManuais: ['a@b.com'],
    ).toJson();
    expect((j['itens'] as List).first['trativaId'], 't1');
    expect((j['itens'] as List).first['motivo'], 'm');
    expect(j['emailsManuais'], ['a@b.com']);
  });

  test('AprovarDesvioRequest omits null comentario', () {
    final j = const AprovarDesvioRequest(emailsManuais: []).toJson();
    expect(j.containsKey('comentario'), false);
    expect(j['emailsManuais'], []);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/ocorrencias/desvio_action_requests_test.dart`
Expected: FAIL — file/types do not exist.

- [ ] **Step 3: Create the request DTOs**

```dart
// lib/features/ocorrencias/model/desvio_action_requests.dart
class AdicionarTrativaRequest {
  final String titulo;
  final String descricao;
  final List<String> evidenciaIds;

  const AdicionarTrativaRequest({
    required this.titulo,
    required this.descricao,
    required this.evidenciaIds,
  });

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'descricao': descricao,
        'evidenciaIds': evidenciaIds,
      };
}

class SubmeterTrativaDesvioRequest {
  final List<String> emailsManuais;
  const SubmeterTrativaDesvioRequest({this.emailsManuais = const []});
  Map<String, dynamic> toJson() => {'emailsManuais': emailsManuais};
}

class AprovarDesvioRequest {
  final String? comentario;
  final List<String> emailsManuais;
  const AprovarDesvioRequest({this.comentario, this.emailsManuais = const []});
  Map<String, dynamic> toJson() => {
        if (comentario != null && comentario!.isNotEmpty) 'comentario': comentario,
        'emailsManuais': emailsManuais,
      };
}

class ItemReprovacao {
  final String trativaId;
  final String motivo;
  const ItemReprovacao({required this.trativaId, required this.motivo});
  Map<String, dynamic> toJson() => {'trativaId': trativaId, 'motivo': motivo};
}

class ReprovarTrativasDesvioRequest {
  final List<ItemReprovacao> itens;
  final List<String> emailsManuais;
  const ReprovarTrativasDesvioRequest({
    required this.itens,
    this.emailsManuais = const [],
  });
  Map<String, dynamic> toJson() => {
        'itens': itens.map((e) => e.toJson()).toList(),
        'emailsManuais': emailsManuais,
      };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/ocorrencias/desvio_action_requests_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/ocorrencias/model/desvio_action_requests.dart test/features/ocorrencias/desvio_action_requests_test.dart
git commit -m "feat(mobile): add Desvio tratativa action request DTOs"
```

---

### Task 3: `DesvioDetail` and `TrativaDesvio` response models

**Files:**
- Create: `lib/features/ocorrencias/model/trativa_desvio.dart`
- Create: `lib/features/ocorrencias/model/desvio_detail.dart`
- Test: `test/features/ocorrencias/desvio_detail_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/ocorrencias/desvio_detail_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/features/ocorrencias/model/desvio_detail.dart';

void main() {
  test('DesvioDetail parses response with tratativas and responsaveis', () {
    final d = DesvioDetail.fromJson({
      'id': 'd-1',
      'estabelecimentoId': 'est-1',
      'estabelecimentoNome': 'Refinaria',
      'titulo': 'EPI inadequado',
      'localizacaoNome': 'Bloco C',
      'descricao': 'desc',
      'dataRegistro': '2026-05-28T10:00:00',
      'orientacaoRealizada': 'orientado',
      'regraDeOuro': true,
      'status': 'AGUARDANDO_APROVACAO',
      'responsavelDesvioId': 'u-d',
      'responsavelDesvioNome': 'Eng A',
      'responsavelTratativaId': 'u-t',
      'responsavelTrivaNome': 'Tec B',
      'tratativas': [
        {
          'id': 't-1', 'titulo': 'Troca de luva', 'descricao': 'feito',
          'status': 'PENDENTE', 'motivoReprovacao': null,
          'numero': 1, 'rodada': 1, 'dtCriacao': '2026-05-28T11:00:00',
          'evidencias': [{'id': 'e-1', 'nome': 'foto.jpg', 'url': 'http://x/e-1'}],
        }
      ],
      'historico': [],
    });
    expect(d.id, 'd-1');
    expect(d.status, 'AGUARDANDO_APROVACAO');
    expect(d.responsavelDesvioId, 'u-d');
    expect(d.responsavelTratativaId, 'u-t');
    expect(d.responsavelTratativaNome, 'Tec B');
    expect(d.tratativas.length, 1);
    expect(d.tratativas.first.status, 'PENDENTE');
    expect(d.tratativas.first.rodada, 1);
    expect(d.tratativas.first.evidencias.first.url, 'http://x/e-1');
  });

  test('DesvioDetail tolerates missing lists', () {
    final d = DesvioDetail.fromJson({
      'id': 'd-2', 'titulo': 'X', 'status': 'ABERTO',
    });
    expect(d.tratativas, isEmpty);
    expect(d.historico, isEmpty);
    expect(d.estabelecimentoNome, '');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/ocorrencias/desvio_detail_test.dart`
Expected: FAIL — models do not exist.

- [ ] **Step 3: Create `TrativaDesvio` model**

```dart
// lib/features/ocorrencias/model/trativa_desvio.dart
class EvidenciaInfo {
  final String id;
  final String nome;
  final String? url;
  const EvidenciaInfo({required this.id, required this.nome, this.url});

  factory EvidenciaInfo.fromJson(Map<String, dynamic> j) => EvidenciaInfo(
        id: j['id'] as String,
        nome: j['nome'] as String? ?? '',
        url: j['url'] as String?,
      );
}

class TrativaDesvio {
  final String id;
  final String titulo;
  final String descricao;
  final String status; // PENDENTE | APROVADO | REPROVADO
  final String? motivoReprovacao;
  final int numero;
  final int rodada;
  final String? dtCriacao;
  final List<EvidenciaInfo> evidencias;

  const TrativaDesvio({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.status,
    this.motivoReprovacao,
    required this.numero,
    required this.rodada,
    this.dtCriacao,
    this.evidencias = const [],
  });

  factory TrativaDesvio.fromJson(Map<String, dynamic> j) => TrativaDesvio(
        id: j['id'] as String,
        titulo: j['titulo'] as String? ?? '',
        descricao: j['descricao'] as String? ?? '',
        status: j['status'] as String? ?? 'PENDENTE',
        motivoReprovacao: j['motivoReprovacao'] as String?,
        numero: j['numero'] as int? ?? 0,
        rodada: j['rodada'] as int? ?? 1,
        dtCriacao: j['dtCriacao'] as String?,
        evidencias: (j['evidencias'] as List<dynamic>? ?? [])
            .map((e) => EvidenciaInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
```

- [ ] **Step 4: Create `DesvioDetail` model**

```dart
// lib/features/ocorrencias/model/desvio_detail.dart
import 'trativa_desvio.dart';

class DesvioDetail {
  final String id;
  final String titulo;
  final String status; // ABERTO | AGUARDANDO_TRATATIVA | AGUARDANDO_APROVACAO | CONCLUIDO
  final String estabelecimentoId;
  final String estabelecimentoNome;
  final String? localizacaoNome;
  final String? descricao;
  final String? orientacaoRealizada;
  final bool regraDeOuro;
  final String dataRegistro;
  final String? responsavelDesvioId;
  final String? responsavelDesvioNome;
  final String? responsavelTratativaId;
  final String? responsavelTratativaNome;
  final String? usuarioCriacaoNome;
  final List<TrativaDesvio> tratativas;
  final List<Map<String, dynamic>> historico;

  const DesvioDetail({
    required this.id,
    required this.titulo,
    required this.status,
    this.estabelecimentoId = '',
    this.estabelecimentoNome = '',
    this.localizacaoNome,
    this.descricao,
    this.orientacaoRealizada,
    this.regraDeOuro = false,
    this.dataRegistro = '',
    this.responsavelDesvioId,
    this.responsavelDesvioNome,
    this.responsavelTratativaId,
    this.responsavelTratativaNome,
    this.usuarioCriacaoNome,
    this.tratativas = const [],
    this.historico = const [],
  });

  factory DesvioDetail.fromJson(Map<String, dynamic> j) => DesvioDetail(
        id: j['id'] as String,
        titulo: j['titulo'] as String? ?? '',
        status: j['status'] as String? ?? 'ABERTO',
        estabelecimentoId: j['estabelecimentoId'] as String? ?? '',
        estabelecimentoNome: j['estabelecimentoNome'] as String? ?? '',
        localizacaoNome: j['localizacaoNome'] as String?,
        descricao: j['descricao'] as String?,
        orientacaoRealizada: j['orientacaoRealizada'] as String?,
        regraDeOuro: j['regraDeOuro'] as bool? ?? false,
        dataRegistro: j['dataRegistro'] as String? ?? '',
        responsavelDesvioId: j['responsavelDesvioId'] as String?,
        responsavelDesvioNome: j['responsavelDesvioNome'] as String?,
        responsavelTratativaId: j['responsavelTratativaId'] as String?,
        // NOTE backend key is misspelled "Triva"
        responsavelTratativaNome: j['responsavelTrivaNome'] as String?,
        usuarioCriacaoNome: j['usuarioCriacaoNome'] as String?,
        tratativas: (j['tratativas'] as List<dynamic>? ?? [])
            .map((e) => TrativaDesvio.fromJson(e as Map<String, dynamic>))
            .toList(),
        historico: (j['historico'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>(),
      );

  /// Highest round number present in the tratativas.
  int get rodadaAtual =>
      tratativas.isEmpty ? 0 : tratativas.map((t) => t.rodada).reduce((a, b) => a > b ? a : b);
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/ocorrencias/desvio_detail_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/features/ocorrencias/model/trativa_desvio.dart lib/features/ocorrencias/model/desvio_detail.dart test/features/ocorrencias/desvio_detail_test.dart
git commit -m "feat(mobile): add DesvioDetail and TrativaDesvio response models"
```

---

## Phase B — Repository layer

### Task 4: Add `tipo` param to evidence uploads

**Files:**
- Modify: `lib/features/ocorrencias/repository/evidencia_repository.dart`
- Modify: `lib/features/ocorrencias/repository/evidencia_repository_impl.dart`
- Test: `test/features/ocorrencias/evidencia_repository_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/ocorrencias/evidencia_repository_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:engseg_mobile/features/ocorrencias/model/evidencia_metadata.dart';
import 'package:engseg_mobile/features/ocorrencias/repository/evidencia_repository_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() => registerFallbackValue(RequestOptions(path: '')));

  test('uploadParaDesvio posts to desvio endpoint and parses id', () async {
    final dio = MockDio();
    final repo = EvidenciaRepositoryImpl(dio: dio);
    when(() => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((inv) async => Response(
          requestOptions: RequestOptions(path: inv.positionalArguments.first as String),
          statusCode: 200,
          data: {'id': 'ev-9', 'url': 'http://x/ev-9', 'tipo': 'TRATATIVA'},
        ));

    final res = await repo.uploadParaDesvio(
      'd-1',
      _FakeFile('/tmp/x.jpg'),
      const EvidenciaMetadata(latitude: -22.0, longitude: -47.0, capturedAt: 0),
      tipo: 'TRATATIVA',
    );
    expect(res.id, 'ev-9');
  });
}

// Minimal File stub: MultipartFile.fromFile reads path; in tests we accept it may throw on
// missing file — instead assert the endpoint via a captured argument is out of scope here.
// If file IO is a problem in CI, skip this test with `, skip: true`.
class _FakeFile { _FakeFile(this.path); final String path; }
```

> If `MultipartFile.fromFile` on a non-existent path makes this test flaky in CI, mark it `skip: true` and rely on manual verification. The behavior under test (correct endpoint + `tipo`) is also covered by manual device testing.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/ocorrencias/evidencia_repository_test.dart`
Expected: FAIL — `uploadParaDesvio` has no named `tipo` param (and `_FakeFile` is not a `File`).

> Practical note: `uploadParaDesvio` takes `dart:io` `File`. Adjust the test to pass a real temp file (`File('${Directory.systemTemp.path}/x.jpg')..writeAsBytesSync([0])`) if you keep it. The essential production change is Steps 3–4.

- [ ] **Step 3: Add `tipo` to the interface**

In `lib/features/ocorrencias/repository/evidencia_repository.dart`, add `{String tipo = 'OCORRENCIA'}` to both methods:

```dart
abstract class EvidenciaRepository {
  Future<EvidenciaResponse> uploadParaNc(
    String ncId,
    File foto,
    EvidenciaMetadata meta, {
    String tipo = 'OCORRENCIA',
  });
  Future<EvidenciaResponse> uploadParaDesvio(
    String desvioId,
    File foto,
    EvidenciaMetadata meta, {
    String tipo = 'OCORRENCIA',
  });
}
```

- [ ] **Step 4: Send `tipo` in the impl**

In `lib/features/ocorrencias/repository/evidencia_repository_impl.dart`, change both method signatures to accept `{String tipo = 'OCORRENCIA'}` and add `'tipo': tipo,` to each `FormData.fromMap({...})`. Example for `uploadParaDesvio`:

```dart
  @override
  Future<EvidenciaResponse> uploadParaDesvio(
    String desvioId,
    File foto,
    EvidenciaMetadata meta, {
    String tipo = 'OCORRENCIA',
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(foto.path),
      'tipo': tipo,
      'latitude': meta.latitude.toString(),
      'longitude': meta.longitude.toString(),
      'capturedAt': meta.capturedAt.toString(),
      'origem': 'MOBILE',
      if (meta.cidade != null) 'cidade': meta.cidade,
    });
    final response = await dio.post<Map<String, dynamic>>(
      '/api/evidencias/desvio/$desvioId',
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
        receiveTimeout: const Duration(seconds: 120),
      ),
    );
    return EvidenciaResponse.fromJson(response.data!);
  }
```

Apply the same `tipo` addition to `uploadParaNc`.

- [ ] **Step 5: Run test (or analyze) to verify**

Run: `flutter test test/features/ocorrencias/evidencia_repository_test.dart` (or `flutter analyze lib/features/ocorrencias/repository/evidencia_repository_impl.dart`)
Expected: PASS / no analyzer errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/ocorrencias/repository/evidencia_repository.dart lib/features/ocorrencias/repository/evidencia_repository_impl.dart test/features/ocorrencias/evidencia_repository_test.dart
git commit -m "feat(mobile): support tipo param (OCORRENCIA|TRATATIVA) on evidence upload"
```

---

### Task 5: Extend `DesvioRepository` with detail + tratativa actions

**Files:**
- Modify: `lib/features/ocorrencias/repository/desvio_repository.dart`
- Modify: `lib/features/ocorrencias/repository/desvio_repository_impl.dart`
- Test: `test/features/ocorrencias/desvio_repository_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/ocorrencias/desvio_repository_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:engseg_mobile/features/ocorrencias/model/desvio_action_requests.dart';
import 'package:engseg_mobile/features/ocorrencias/repository/desvio_repository_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late DesvioRepositoryImpl repo;

  setUpAll(() => registerFallbackValue(RequestOptions(path: '')));
  setUp(() {
    dio = MockDio();
    repo = DesvioRepositoryImpl(dio: dio);
  });

  test('buscarDetalhe parses DesvioDetail', () async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: {'id': 'd-1', 'titulo': 'X', 'status': 'ABERTO', 'tratativas': []},
        ));
    final d = await repo.buscarDetalhe('d-1');
    expect(d.id, 'd-1');
    expect(d.status, 'ABERTO');
  });

  test('adicionarTratativa posts request body', () async {
    when(() => dio.post<dynamic>(any(), data: any(named: 'data')))
        .thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''), statusCode: 200));
    await repo.adicionarTratativa(
      'd-1',
      const AdicionarTrativaRequest(titulo: 'T', descricao: 'D', evidenciaIds: ['e1']),
    );
    verify(() => dio.post<dynamic>('/api/desvios/d-1/tratativas',
        data: any(named: 'data'))).called(1);
  });

  test('abrirTratativa posts to endpoint', () async {
    when(() => dio.post<dynamic>(any())).thenAnswer((_) async =>
        Response(requestOptions: RequestOptions(path: ''), statusCode: 200));
    await repo.abrirTratativa('d-1');
    verify(() => dio.post<dynamic>('/api/desvios/d-1/abrir-tratativa')).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/ocorrencias/desvio_repository_test.dart`
Expected: FAIL — `buscarDetalhe`, `adicionarTratativa`, `abrirTratativa` not defined.

- [ ] **Step 3: Update the interface**

Replace `lib/features/ocorrencias/repository/desvio_repository.dart`:

```dart
import '../model/desvio_summary.dart';
import '../model/desvio_detail.dart';
import '../model/criar_desvio_request.dart';
import '../model/desvio_action_requests.dart';

abstract class DesvioRepository {
  Future<List<DesvioSummary>> listar({String? estabelecimentoId});
  Future<DesvioDetail> buscarDetalhe(String id);
  Future<Map<String, dynamic>> criar(CriarDesvioRequest request);
  Future<void> abrirTratativa(String id);
  Future<void> adicionarTratativa(String id, AdicionarTrativaRequest request);
  Future<void> removerTratativa(String id, String trativaId);
  Future<void> submeterTratativa(String id, SubmeterTrativaDesvioRequest request);
  Future<void> aprovar(String id, AprovarDesvioRequest request);
  Future<void> reprovar(String id, ReprovarTrativasDesvioRequest request);
}
```

- [ ] **Step 4: Update the impl + add a `desvioDetailProvider`**

Replace `lib/features/ocorrencias/repository/desvio_repository_impl.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/desvio_summary.dart';
import '../model/desvio_detail.dart';
import '../model/criar_desvio_request.dart';
import '../model/desvio_action_requests.dart';
import 'desvio_repository.dart';
import '../../../core/network/dio_client.dart';

final desvioRepositoryProvider = Provider<DesvioRepository>((ref) {
  return DesvioRepositoryImpl(dio: ref.watch(dioProvider));
});

final desvioListProvider = FutureProvider.family<List<DesvioSummary>, String>(
  (ref, estabelecimentoId) async {
    return ref.read(desvioRepositoryProvider).listar(
          estabelecimentoId: estabelecimentoId,
        );
  },
);

final desvioDetailProvider = FutureProvider.family<DesvioDetail, String>(
  (ref, id) async {
    return ref.watch(desvioRepositoryProvider).buscarDetalhe(id);
  },
);

class DesvioRepositoryImpl implements DesvioRepository {
  final Dio dio;
  DesvioRepositoryImpl({required this.dio});

  @override
  Future<List<DesvioSummary>> listar({String? estabelecimentoId}) async {
    final response = await dio.get<List<dynamic>>(
      '/api/desvios',
      queryParameters: {
        if (estabelecimentoId != null) 'estabelecimentoId': estabelecimentoId,
      },
    );
    return (response.data ?? [])
        .map((e) => DesvioSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DesvioDetail> buscarDetalhe(String id) async {
    final response = await dio.get<Map<String, dynamic>>('/api/desvios/$id');
    return DesvioDetail.fromJson(response.data!);
  }

  @override
  Future<Map<String, dynamic>> criar(CriarDesvioRequest request) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/api/desvios',
      data: request.toJson(),
    );
    return response.data!;
  }

  @override
  Future<void> abrirTratativa(String id) async {
    await dio.post<dynamic>('/api/desvios/$id/abrir-tratativa');
  }

  @override
  Future<void> adicionarTratativa(String id, AdicionarTrativaRequest request) async {
    await dio.post<dynamic>('/api/desvios/$id/tratativas', data: request.toJson());
  }

  @override
  Future<void> removerTratativa(String id, String trativaId) async {
    await dio.delete<dynamic>('/api/desvios/$id/tratativas/$trativaId');
  }

  @override
  Future<void> submeterTratativa(String id, SubmeterTrativaDesvioRequest request) async {
    await dio.post<dynamic>('/api/desvios/$id/submeter-tratativa', data: request.toJson());
  }

  @override
  Future<void> aprovar(String id, AprovarDesvioRequest request) async {
    await dio.post<dynamic>('/api/desvios/$id/aprovar', data: request.toJson());
  }

  @override
  Future<void> reprovar(String id, ReprovarTrativasDesvioRequest request) async {
    await dio.post<dynamic>('/api/desvios/$id/reprovar', data: request.toJson());
  }
}
```

> Action methods return `void`; the UI re-fetches via `ref.invalidate(desvioDetailProvider(id))`. This avoids assuming the action response shape.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/ocorrencias/desvio_repository_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/features/ocorrencias/repository/desvio_repository.dart lib/features/ocorrencias/repository/desvio_repository_impl.dart test/features/ocorrencias/desvio_repository_test.dart
git commit -m "feat(mobile): extend DesvioRepository with detail and tratativa actions"
```

---

### Task 6: Default-emails model + provider

**Files:**
- Create: `lib/features/ocorrencias/model/email_padrao.dart`
- Create: `lib/features/ocorrencias/repository/email_padrao_repository.dart`
- Test: `test/features/ocorrencias/email_padrao_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/ocorrencias/email_padrao_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/features/ocorrencias/model/email_padrao.dart';

void main() {
  test('EmailPadrao parses', () {
    final e = EmailPadrao.fromJson({
      'id': 'p-1', 'email': 'a@b.com', 'descricao': 'Gestor', 'empresaId': 'emp-1',
    });
    expect(e.id, 'p-1');
    expect(e.email, 'a@b.com');
    expect(e.descricao, 'Gestor');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/ocorrencias/email_padrao_test.dart`
Expected: FAIL — model missing.

- [ ] **Step 3: Create the model**

```dart
// lib/features/ocorrencias/model/email_padrao.dart
class EmailPadrao {
  final String id;
  final String email;
  final String? descricao;
  const EmailPadrao({required this.id, required this.email, this.descricao});

  factory EmailPadrao.fromJson(Map<String, dynamic> j) => EmailPadrao(
        id: j['id'] as String,
        email: j['email'] as String,
        descricao: j['descricao'] as String?,
      );
}
```

- [ ] **Step 4: Create the provider**

```dart
// lib/features/ocorrencias/repository/email_padrao_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/email_padrao.dart';
import '../../../core/network/dio_client.dart';

typedef EmailPadraoKey = ({String estabelecimentoId, String empresaId});

/// Default-notification emails for an estabelecimento+empresa. Returns [] on any error
/// so the editor can still offer manual emails.
final emailsPadraoProvider =
    FutureProvider.family<List<EmailPadrao>, EmailPadraoKey>((ref, key) async {
  final dio = ref.watch(dioProvider);
  try {
    final r = await dio.get<List<dynamic>>(
      '/api/emails-padrao',
      queryParameters: {
        'estabelecimentoId': key.estabelecimentoId,
        'empresaId': key.empresaId,
      },
    );
    return (r.data ?? [])
        .map((e) => EmailPadrao.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/ocorrencias/email_padrao_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/ocorrencias/model/email_padrao.dart lib/features/ocorrencias/repository/email_padrao_repository.dart test/features/ocorrencias/email_padrao_test.dart
git commit -m "feat(mobile): add default-emails model and provider"
```

---

## Phase C — Reusable form widgets

### Task 7: Email editor widget

**Files:**
- Create: `lib/features/ocorrencias/widgets/email_editor.dart`

- [ ] **Step 1: Create the widget**

```dart
// lib/features/ocorrencias/widgets/email_editor.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/prototype_ui.dart';
import '../repository/email_padrao_repository.dart';

/// Lets the user toggle default-notification emails off (excluded) and add manual ones.
/// Reports current selection via [onChanged] as (manuais, excluidos).
class EmailEditor extends ConsumerStatefulWidget {
  final String estabelecimentoId;
  final String empresaId;
  final void Function(List<String> manuais, List<String> excluidos) onChanged;

  const EmailEditor({
    super.key,
    required this.estabelecimentoId,
    required this.empresaId,
    required this.onChanged,
  });

  @override
  ConsumerState<EmailEditor> createState() => _EmailEditorState();
}

class _EmailEditorState extends ConsumerState<EmailEditor> {
  final _manuais = <String>[];
  final _excluidos = <String>{};
  final _controller = TextEditingController();

  void _emit() => widget.onChanged(_manuais, _excluidos.toList());

  void _addManual() {
    final v = _controller.text.trim();
    if (v.isEmpty || !v.contains('@')) return;
    setState(() {
      _manuais.add(v);
      _controller.clear();
    });
    _emit();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padraoAsync = ref.watch(emailsPadraoProvider((
      estabelecimentoId: widget.estabelecimentoId,
      empresaId: widget.empresaId,
    )));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProtoSectionTitle('Notificacoes por e-mail'),
        const SizedBox(height: 8),
        padraoAsync.when(
          loading: () => const SizedBox(
            height: 18, width: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: ProtoColors.blue),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (lista) {
            if (lista.isEmpty) return const SizedBox.shrink();
            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: lista.map((e) {
                final excluido = _excluidos.contains(e.email);
                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    setState(() {
                      if (excluido) {
                        _excluidos.remove(e.email);
                      } else {
                        _excluidos.add(e.email);
                      }
                    });
                    _emit();
                  },
                  child: ProtoPill(
                    label: e.email,
                    icon: excluido ? Icons.close_rounded : Icons.check_rounded,
                    bg: excluido ? ProtoColors.surface2 : const Color(0xFF0B3A1C),
                    fg: excluido ? ProtoColors.muted : ProtoColors.green,
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: ProtoColors.text, fontSize: 13),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Adicionar e-mail manual',
                  hintStyle: TextStyle(color: ProtoColors.muted, fontSize: 13),
                  isDense: true,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: ProtoColors.border),
                  ),
                ),
                onSubmitted: (_) => _addManual(),
              ),
            ),
            ProtoIconButton(icon: Icons.add_rounded, onTap: _addManual),
          ],
        ),
        if (_manuais.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _manuais
                .asMap()
                .entries
                .map((entry) => InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        setState(() => _manuais.removeAt(entry.key));
                        _emit();
                      },
                      child: ProtoPill(
                        label: entry.value,
                        icon: Icons.close_rounded,
                        bg: const Color(0xFF1A2A4A),
                        fg: ProtoColors.blue,
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 2: Analyze**

Run: `flutter analyze lib/features/ocorrencias/widgets/email_editor.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/ocorrencias/widgets/email_editor.dart
git commit -m "feat(mobile): add reusable email editor widget"
```

---

### Task 8: Risk picker widget (severidade × probabilidade)

**Files:**
- Create: `lib/features/ocorrencias/widgets/risk_picker.dart`

- [ ] **Step 1: Create the widget**

```dart
// lib/features/ocorrencias/widgets/risk_picker.dart
import 'package:flutter/material.dart';
import '../../../shared/widgets/prototype_ui.dart';

/// Two 1..N segmented rows for severidade (1-5) and probabilidade (1-4),
/// plus a derived nivel-de-risco label. Reports values via callbacks.
class RiskPicker extends StatelessWidget {
  final int severidade;
  final int probabilidade;
  final ValueChanged<int> onSeveridade;
  final ValueChanged<int> onProbabilidade;

  const RiskPicker({
    super.key,
    required this.severidade,
    required this.probabilidade,
    required this.onSeveridade,
    required this.onProbabilidade,
  });

  @override
  Widget build(BuildContext context) {
    final score = severidade * probabilidade;
    final (label, color) = _nivel(score);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProtoSectionTitle('Severidade'),
        const SizedBox(height: 8),
        _Ramp(count: 5, value: severidade, onTap: onSeveridade),
        const SizedBox(height: 16),
        const ProtoSectionTitle('Probabilidade'),
        const SizedBox(height: 8),
        _Ramp(count: 4, value: probabilidade, onTap: onProbabilidade),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Nivel de risco',
                style: TextStyle(color: ProtoColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            ProtoPill(label: label, bg: color.withValues(alpha: .18), fg: color),
          ],
        ),
      ],
    );
  }

  (String, Color) _nivel(int score) {
    if (score >= 15) return ('CRITICO', ProtoColors.red);
    if (score >= 9) return ('ALTO', ProtoColors.orange);
    if (score >= 4) return ('MEDIO', ProtoColors.yellow);
    return ('BAIXO', ProtoColors.green);
  }
}

class _Ramp extends StatelessWidget {
  final int count;
  final int value;
  final ValueChanged<int> onTap;
  const _Ramp({required this.count, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final n = i + 1;
        final active = n <= value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == count - 1 ? 0 : 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onTap(n),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? ProtoColors.blue : ProtoColors.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ProtoColors.border),
                ),
                child: Text('$n',
                    style: TextStyle(
                        color: active ? Colors.white : ProtoColors.muted,
                        fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        );
      }),
    );
  }
}
```

- [ ] **Step 2: Analyze + commit**

```bash
flutter analyze lib/features/ocorrencias/widgets/risk_picker.dart
git add lib/features/ocorrencias/widgets/risk_picker.dart
git commit -m "feat(mobile): add NC risk picker widget"
```

---

## Phase D — Creation flow (WizardPage)

### Task 9: WizardPage scaffold — read handoff, common fields, submit plumbing

**Files:**
- Modify: `lib/features/wizard/wizard_page.dart` (currently a placeholder)

Context: route is `/wizard/:tipo` (`tipo` is `nc` or `desvio`), `extra` is a `Map` with `fotoPath`, `latitude`, `longitude`, `capturedAt` (epoch ms), `cidade`. Photos also live in `captureProvider` (List<XFile>). The establishment is the current `workspaceProvider!.estabelecimento`.

- [ ] **Step 1: Replace the placeholder with the scaffold**

```dart
// lib/features/wizard/wizard_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../shared/providers/capture_provider.dart';
import '../../shared/widgets/prototype_ui.dart';
import '../auth/provider/auth_provider.dart';
import '../ocorrencias/model/criar_nc_request.dart';
import '../ocorrencias/model/criar_desvio_request.dart';
import '../ocorrencias/model/evidencia_metadata.dart';
import '../ocorrencias/repository/desvio_repository_impl.dart';
import '../ocorrencias/repository/nc_repository_impl.dart';
import '../ocorrencias/repository/evidencia_repository_impl.dart';
import '../ocorrencias/repository/support_repository_impl.dart';
import '../ocorrencias/widgets/email_editor.dart';
import '../ocorrencias/widgets/risk_picker.dart';

class WizardPage extends ConsumerStatefulWidget {
  final String tipo; // 'nc' | 'desvio'
  final Map<String, dynamic>? extra;
  const WizardPage({super.key, required this.tipo, this.extra});

  @override
  ConsumerState<WizardPage> createState() => _WizardPageState();
}

class _WizardPageState extends ConsumerState<WizardPage> {
  bool get isNc => widget.tipo.toLowerCase() == 'nc';

  // common
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  bool _regraDeOuro = false;
  String? _localizacaoId;
  List<String> _emailsManuais = [];
  List<String> _emailsExcluidos = [];

  // desvio
  final _orientacao = TextEditingController();
  String? _responsavelDesvioId;
  String? _responsavelTratativaId;

  // nc
  int _severidade = 1;
  int _probabilidade = 1;
  bool _reincidencia = false;
  final _normaIds = <String>{};
  String? _responsavelNcId;

  bool _saving = false;
  String? _error;

  EvidenciaMetadata get _meta {
    final e = widget.extra ?? const {};
    return EvidenciaMetadata(
      latitude: (e['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (e['longitude'] as num?)?.toDouble() ?? 0,
      capturedAt: (e['capturedAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      cidade: e['cidade'] as String?,
    );
  }

  List<File> get _photos {
    final fromProvider = ref.read(captureProvider).map((x) => File(x.path)).toList();
    if (fromProvider.isNotEmpty) return fromProvider;
    final p = widget.extra?['fotoPath'] as String?;
    return p != null ? [File(p)] : [];
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _orientacao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspaceProvider);
    final estabId = workspace?.estabelecimento.id;

    return Scaffold(
      backgroundColor: ProtoColors.bg,
      appBar: AppBar(
        backgroundColor: ProtoColors.bg,
        foregroundColor: ProtoColors.text,
        title: Text(isNc ? 'Nova Nao Conformidade' : 'Novo Desvio'),
      ),
      body: estabId == null
          ? const Center(
              child: Text('Selecione um estabelecimento primeiro',
                  style: TextStyle(color: ProtoColors.muted)))
          : _buildForm(context, estabId),
    );
  }

  Widget _buildForm(BuildContext context, String estabId) {
    final empresaId = ref.watch(workspaceProvider)!.empresa.id;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        _photoStrip(),
        const SizedBox(height: 16),
        _field('Titulo', _titulo),
        const SizedBox(height: 14),
        _field('Descricao', _descricao, maxLines: 3),
        const SizedBox(height: 14),
        _localizacaoDropdown(estabId),
        const SizedBox(height: 14),
        if (isNc) ..._ncFields(estabId) else ..._desvioFields(estabId),
        const SizedBox(height: 18),
        EmailEditor(
          estabelecimentoId: estabId,
          empresaId: empresaId,
          onChanged: (m, x) {
            _emailsManuais = m;
            _emailsExcluidos = x;
          },
        ),
        const SizedBox(height: 18),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: ProtoColors.blue,
          title: const Text('Regra de ouro',
              style: TextStyle(color: ProtoColors.text, fontWeight: FontWeight.w700)),
          value: _regraDeOuro,
          onChanged: (v) => setState(() => _regraDeOuro = v),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: ProtoColors.red, fontSize: 13)),
        ],
        const SizedBox(height: 16),
        _submitButton(estabId),
      ],
    );
  }

  Widget _photoStrip() {
    final photos = _photos;
    if (photos.isEmpty) {
      return ProtoCard(
        child: Row(
          children: const [
            Icon(Icons.image_not_supported_outlined, color: ProtoColors.muted),
            SizedBox(width: 8),
            Text('Sem foto', style: TextStyle(color: ProtoColors.muted)),
          ],
        ),
      );
    }
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(photos[i], width: 84, height: 84, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: ProtoColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          maxLines: maxLines,
          style: const TextStyle(color: ProtoColors.text, fontSize: 14),
          decoration: const InputDecoration(
            isDense: true,
            filled: true,
            fillColor: ProtoColors.surface,
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: ProtoColors.border)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ProtoColors.blue)),
          ),
        ),
      ],
    );
  }

  Widget _localizacaoDropdown(String estabId) {
    final locs = ref.watch(localizacoesProvider(estabId));
    return locs.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) => _dropdown<String>(
        label: 'Localizacao (opcional)',
        value: _localizacaoId,
        items: [
          const DropdownMenuItem(value: null, child: Text('—')),
          ...list.map((l) => DropdownMenuItem(value: l.id, child: Text(l.nome))),
        ],
        onChanged: (v) => setState(() => _localizacaoId = v),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: ProtoColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: ProtoColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ProtoColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              dropdownColor: ProtoColors.surface,
              value: value,
              style: const TextStyle(color: ProtoColors.text, fontSize: 14),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // Implemented in Task 10 / 11.
  List<Widget> _desvioFields(String estabId) => const [];
  List<Widget> _ncFields(String estabId) => const [];
  Widget _submitButton(String estabId) => const SizedBox.shrink();
}
```

- [ ] **Step 2: Analyze**

Run: `flutter analyze lib/features/wizard/wizard_page.dart`
Expected: No issues (the `_desvioFields/_ncFields/_submitButton` stubs return empty for now).

- [ ] **Step 3: Commit**

```bash
git add lib/features/wizard/wizard_page.dart
git commit -m "feat(mobile): WizardPage scaffold with photo strip, common fields, email editor"
```

---

### Task 10: Desvio form fields + submit (create + upload)

**Files:**
- Modify: `lib/features/wizard/wizard_page.dart`

- [ ] **Step 1: Replace `_desvioFields` and add the desvio submit path**

Replace the `_desvioFields(String estabId) => const [];` stub with:

```dart
  List<Widget> _desvioFields(String estabId) {
    final usuarios = ref.watch(usuariosProvider(estabId));
    return [
      _field('Orientacao realizada', _orientacao, maxLines: 2),
      const SizedBox(height: 14),
      usuarios.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (list) => Column(
          children: [
            _dropdown<String>(
              label: 'Responsavel pelo desvio (aprovador)',
              value: _responsavelDesvioId,
              items: [
                const DropdownMenuItem(value: null, child: Text('—')),
                ...list.map((u) => DropdownMenuItem(value: u.id, child: Text(u.nome))),
              ],
              onChanged: (v) => setState(() => _responsavelDesvioId = v),
            ),
            const SizedBox(height: 14),
            _dropdown<String>(
              label: 'Responsavel pela tratativa',
              value: _responsavelTratativaId,
              items: [
                const DropdownMenuItem(value: null, child: Text('—')),
                ...list.map((u) => DropdownMenuItem(value: u.id, child: Text(u.nome))),
              ],
              onChanged: (v) => setState(() => _responsavelTratativaId = v),
            ),
          ],
        ),
      ),
    ];
  }

  Future<void> _submitDesvio(String estabId) async {
    setState(() { _saving = true; _error = null; });
    try {
      final req = CriarDesvioRequest(
        estabelecimentoId: estabId,
        titulo: _titulo.text.trim(),
        descricao: _descricao.text.trim().isEmpty ? null : _descricao.text.trim(),
        orientacaoRealizada: _orientacao.text.trim().isEmpty ? null : _orientacao.text.trim(),
        regraDeOuro: _regraDeOuro,
        localizacaoId: _localizacaoId,
        responsavelDesvioId: _responsavelDesvioId,
        responsavelTratativaId: _responsavelTratativaId,
        emailsManuais: _emailsManuais,
        emailsPadraoExcluidos: _emailsExcluidos,
      );
      final created = await ref.read(desvioRepositoryProvider).criar(req);
      final id = created['id'] as String;
      await _uploadPhotos(id, isNc: false);
      if (!mounted) return;
      ref.invalidate(desvioListProvider(estabId));
      context.go('/desvio/$id');
    } catch (e) {
      setState(() => _error = 'Falha ao criar desvio: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadPhotos(String id, {required bool isNc}) async {
    final repo = ref.read(evidenciaRepositoryProvider);
    for (final f in _photos) {
      if (isNc) {
        await repo.uploadParaNc(id, f, _meta);
      } else {
        await repo.uploadParaDesvio(id, f, _meta);
      }
    }
    ref.read(captureProvider.notifier).clear();
  }
```

- [ ] **Step 2: Replace `_submitButton` to call the right path with validation**

Replace the `_submitButton(String estabId) => const SizedBox.shrink();` stub with:

```dart
  Widget _submitButton(String estabId) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ProtoColors.blue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _saving ? null : () => _onSubmit(estabId),
        child: _saving
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(isNc ? 'Registrar NC' : 'Registrar Desvio',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
    );
  }

  void _onSubmit(String estabId) {
    if (_titulo.text.trim().isEmpty) {
      setState(() => _error = 'Informe um titulo');
      return;
    }
    if (isNc && _descricao.text.trim().isEmpty) {
      setState(() => _error = 'Descricao e obrigatoria para NC');
      return;
    }
    if (isNc) {
      _submitNc(estabId);
    } else {
      _submitDesvio(estabId);
    }
  }
```

- [ ] **Step 3: Analyze**

Run: `flutter analyze lib/features/wizard/wizard_page.dart`
Expected: One error — `_submitNc` not yet defined (added in Task 11). That is expected; do NOT commit a non-compiling file. Proceed to Task 11, then analyze+commit together.

> If you prefer green-between-tasks, temporarily add `void _submitNc(String estabId) {}` and remove it in Task 11. Otherwise continue directly.

---

### Task 11: NC form fields + submit

**Files:**
- Modify: `lib/features/wizard/wizard_page.dart`

- [ ] **Step 1: Replace `_ncFields` stub**

```dart
  List<Widget> _ncFields(String estabId) {
    final usuarios = ref.watch(usuariosProvider(estabId));
    final normas = ref.watch(normasProvider);
    return [
      RiskPicker(
        severidade: _severidade,
        probabilidade: _probabilidade,
        onSeveridade: (v) => setState(() => _severidade = v),
        onProbabilidade: (v) => setState(() => _probabilidade = v),
      ),
      const SizedBox(height: 16),
      normas.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (list) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProtoSectionTitle('Normas'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: list.map((n) {
                final sel = _normaIds.contains(n.id);
                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => setState(() {
                    sel ? _normaIds.remove(n.id) : _normaIds.add(n.id);
                  }),
                  child: ProtoPill(
                    label: n.codigo,
                    bg: sel ? const Color(0xFF1A2A4A) : ProtoColors.surface2,
                    fg: sel ? ProtoColors.blue : ProtoColors.muted,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      usuarios.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (list) => Column(
          children: [
            _dropdown<String>(
              label: 'Responsavel pela NC (validador)',
              value: _responsavelNcId,
              items: [
                const DropdownMenuItem(value: null, child: Text('—')),
                ...list.map((u) => DropdownMenuItem(value: u.id, child: Text(u.nome))),
              ],
              onChanged: (v) => setState(() => _responsavelNcId = v),
            ),
            const SizedBox(height: 14),
            _dropdown<String>(
              label: 'Responsavel pela tratativa',
              value: _responsavelTratativaId,
              items: [
                const DropdownMenuItem(value: null, child: Text('—')),
                ...list.map((u) => DropdownMenuItem(value: u.id, child: Text(u.nome))),
              ],
              onChanged: (v) => setState(() => _responsavelTratativaId = v),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeColor: ProtoColors.blue,
        title: const Text('Reincidencia',
            style: TextStyle(color: ProtoColors.text, fontWeight: FontWeight.w700)),
        value: _reincidencia,
        onChanged: (v) => setState(() => _reincidencia = v),
      ),
    ];
  }

  Future<void> _submitNc(String estabId) async {
    setState(() { _saving = true; _error = null; });
    try {
      final req = CriarNcRequest(
        estabelecimentoId: estabId,
        titulo: _titulo.text.trim(),
        descricao: _descricao.text.trim(),
        severidade: _severidade,
        probabilidade: _probabilidade,
        regraDeOuro: _regraDeOuro,
        reincidencia: _reincidencia,
        localizacaoId: _localizacaoId,
        responsavelNcId: _responsavelNcId,
        responsavelTrativaId: _responsavelTratativaId,
        normaIds: _normaIds.toList(),
        emailsManuais: _emailsManuais,
        emailsPadraoExcluidos: _emailsExcluidos,
      );
      final nc = await ref.read(ncRepositoryProvider).criar(req);
      await _uploadPhotos(nc.id, isNc: true);
      if (!mounted) return;
      ref.invalidate(ncListProvider(estabId));
      context.go('/oc/${nc.id}');
    } catch (e) {
      setState(() => _error = 'Falha ao criar NC: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
```

> If you added a temporary `_submitNc` stub in Task 10, remove it now.

- [ ] **Step 2: Analyze the whole file**

Run: `flutter analyze lib/features/wizard/wizard_page.dart`
Expected: No issues.

- [ ] **Step 3: Manual smoke test on device**

Run: `flutter run -d f868b62`
- From the feed FAB choose **Desvio**, capture a photo, fill title + responsáveis, tap Registrar Desvio → should land on `/desvio/:id` (detail comes in Phase E; for now a route-not-found is acceptable until Task 13). Verify a desvio is created in the web app.
- Repeat for **NC**: choose severidade/probabilidade, a norma, tap Registrar NC → lands on `/oc/:id` (existing NC detail) and the photo appears under Evidências.

- [ ] **Step 4: Commit**

```bash
git add lib/features/wizard/wizard_page.dart
git commit -m "feat(mobile): NC and Desvio creation forms with photo upload"
```

---

## Phase E — Desvio list, detail & tratativa actions

### Task 12: Desvio feed page + route + nav entry

**Files:**
- Create: `lib/features/ocorrencias/desvio_feed_page.dart`
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/shared/widgets/engseg_shell.dart`

- [ ] **Step 1: Create `DesvioFeedPage`** (mirrors `feed_page.dart`)

```dart
// lib/features/ocorrencias/desvio_feed_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/data/mock_data.dart';
import '../../shared/widgets/prototype_ui.dart';
import '../auth/provider/auth_provider.dart';
import 'model/desvio_summary.dart';
import 'repository/desvio_repository_impl.dart';

class DesvioFeedPage extends ConsumerWidget {
  const DesvioFeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(workspaceProvider)?.estabelecimento.id;
    final async = workspaceId != null
        ? ref.watch(desvioListProvider(workspaceId))
        : const AsyncData<List<DesvioSummary>>([]);

    return Scaffold(
      backgroundColor: ProtoColors.bg,
      appBar: AppBar(
        backgroundColor: ProtoColors.bg,
        foregroundColor: ProtoColors.text,
        title: const Text('Desvios'),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: ProtoColors.blue,
          backgroundColor: const Color(0xFF1A2233),
          onRefresh: () async {
            if (workspaceId != null) {
              ref.invalidate(desvioListProvider(workspaceId));
              await ref.read(desvioListProvider(workspaceId).future)
                  .catchError((_) => <DesvioSummary>[]);
            }
          },
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Erro ao carregar: $e',
                  style: const TextStyle(color: ProtoColors.red, fontSize: 13)),
            ),
            data: (list) => list.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 80),
                    Center(child: Text('Nenhum desvio encontrado',
                        style: TextStyle(color: ProtoColors.muted))),
                  ])
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 104),
                    children: list.map((d) => _DesvioCard(d: d)).toList(),
                  ),
          ),
        ),
      ),
    );
  }
}

class _DesvioCard extends StatelessWidget {
  final DesvioSummary d;
  const _DesvioCard({required this.d});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/desvio/${d.id}'),
        child: ProtoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 6, runSpacing: 4, children: [
                const ProtoPill(label: 'Desvio', bg: Color(0xFF4A390A), fg: ProtoColors.yellow),
                ProtoPill(
                  label: statusLabel[d.status] ?? d.status,
                  bg: ProtoColors.surface2,
                  fg: ProtoColors.blue,
                ),
              ]),
              const SizedBox(height: 8),
              Text(d.titulo,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: ProtoColors.text, fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.place_outlined, size: 12, color: ProtoColors.muted2),
                const SizedBox(width: 4),
                Flexible(child: Text(d.estabelecimentoNome,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: ProtoColors.muted, fontSize: 11, fontWeight: FontWeight.w700))),
                const SizedBox(width: 10),
                const Icon(Icons.schedule_rounded, size: 12, color: ProtoColors.muted2),
                const SizedBox(width: 4),
                Text(d.dataRegistro,
                    style: const TextStyle(color: ProtoColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Register routes in `app_router.dart`**

Add the import near the others: `import '../../features/ocorrencias/desvio_feed_page.dart';` and `import '../../features/ocorrencias/desvio_detail_page.dart';` (file created in Task 13).

Inside the `ShellRoute`'s `routes:` list (next to `/feed`), add:

```dart
          GoRoute(path: '/desvios', builder: (_, __) => const DesvioFeedPage()),
```

After the `/oc/:id` route, add:

```dart
      GoRoute(path: '/desvio/:id', builder: (_, state) => DesvioDetailPage(id: state.pathParameters['id']!)),
```

- [ ] **Step 3: Add a "Desvios" nav item in `engseg_shell.dart`**

In the `bottomNavigationBar` `Row`, replace the existing children with one that includes Desvios (keep the centered FAB gap):

```dart
        child: const Row(
          children: [
            _NavItem(path: '/feed', icon: Icons.shield_outlined, label: 'NCs'),
            _NavItem(path: '/desvios', icon: Icons.local_fire_department_outlined, label: 'Desvios'),
            Expanded(child: SizedBox()),
            _NavItem(path: '/notif', icon: Icons.notifications_none_rounded, label: 'Avisos'),
            _NavItem(path: '/profile', icon: Icons.person_outline_rounded, label: 'Perfil'),
          ],
        ),
```

> This drops the Dashboard tab from the bar to make room. If Dashboard must stay, instead add Desvios and accept 5 items, or move Dashboard into the profile/menu. Confirm with the product owner; default here keeps 4 items + FAB.

- [ ] **Step 4: Analyze**

Run: `flutter analyze lib/features/ocorrencias/desvio_feed_page.dart lib/core/router/app_router.dart lib/shared/widgets/engseg_shell.dart`
Expected: One error — `DesvioDetailPage` undefined until Task 13. Proceed to Task 13, then analyze + commit together.

---

### Task 13: Desvio detail page + tratativa actions

**Files:**
- Create: `lib/features/ocorrencias/desvio_detail_page.dart`

Permissions (from web + memory):
- **Aprovar/Reprovar** visible when `session.isAdmin || session.perfil == 'ENGENHEIRO' || session.id == responsavelDesvioId`, and status is `AGUARDANDO_APROVACAO`.
- **Abrir/Adicionar/Submeter tratativa** visible when `session.isAdmin || session.id == responsavelTratativaId`. (TECNICO only acts when it is the tratativa responsável.)
- Desvio evidence upload is backend-restricted to TECNICO/ENGENHEIRO; if an EXTERNO is the tratativa responsável, adding a tratativa photo will 403 — surface the error message.

- [ ] **Step 1: Create the detail page**

```dart
// lib/features/ocorrencias/desvio_detail_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../shared/data/mock_data.dart';
import '../../shared/widgets/prototype_ui.dart';
import '../auth/provider/auth_provider.dart';
import 'model/desvio_detail.dart';
import 'model/trativa_desvio.dart';
import 'model/evidencia_metadata.dart';
import 'model/desvio_action_requests.dart';
import 'repository/desvio_repository_impl.dart';
import 'repository/evidencia_repository_impl.dart';

class DesvioDetailPage extends ConsumerWidget {
  final String id;
  const DesvioDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(desvioDetailProvider(id));
    return Scaffold(
      backgroundColor: ProtoColors.bg,
      appBar: AppBar(
        backgroundColor: ProtoColors.bg,
        foregroundColor: ProtoColors.text,
        title: const Text('Desvio'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erro: $e', style: const TextStyle(color: ProtoColors.red)),
        ),
        data: (d) => _Body(d: d),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final DesvioDetail d;
  const _Body({required this.d});
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

  DesvioDetail get d => widget.d;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(desvioDetailProvider(d.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha: $e'), backgroundColor: ProtoColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider).valueOrNull;
    final isResponsavelTratativa =
        session != null && session.id == d.responsavelTratativaId;
    final isResponsavelDesvio = session != null && session.id == d.responsavelDesvioId;
    final isApprover = session != null &&
        (session.isAdmin || session.perfil == 'ENGENHEIRO' || isResponsavelDesvio);
    final canTratar = session != null && (session.isAdmin || isResponsavelTratativa);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        _header(),
        const SizedBox(height: 16),
        _geral(),
        const SizedBox(height: 16),
        _tratativasSection(),
        const SizedBox(height: 20),
        if (!_busy) ..._actions(canTratar: canTratar, isApprover: isApprover),
        if (_busy) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _header() {
    return Row(children: [
      const ProtoPill(label: 'Desvio', bg: Color(0xFF4A390A), fg: ProtoColors.yellow),
      const SizedBox(width: 8),
      ProtoPill(
        label: statusLabel[d.status] ?? d.status,
        bg: ProtoColors.surface2,
        fg: ProtoColors.blue,
      ),
    ]);
  }

  Widget _geral() {
    return ProtoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d.titulo,
              style: const TextStyle(color: ProtoColors.text, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (d.descricao != null) _line('Descricao', d.descricao!),
          if (d.orientacaoRealizada != null) _line('Orientacao', d.orientacaoRealizada!),
          if (d.localizacaoNome != null) _line('Local', d.localizacaoNome!),
          if (d.responsavelDesvioNome != null) _line('Resp. desvio', d.responsavelDesvioNome!),
          if (d.responsavelTratativaNome != null) _line('Resp. tratativa', d.responsavelTratativaNome!),
          _line('Registro', d.dataRegistro),
        ],
      ),
    );
  }

  Widget _line(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 110,
            child: Text(k, style: const TextStyle(color: ProtoColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          Expanded(child: Text(v, style: const TextStyle(color: ProtoColors.text, fontSize: 13))),
        ]),
      );

  Widget _tratativasSection() {
    if (d.tratativas.isEmpty) {
      return const ProtoCard(
        child: Text('Nenhuma tratativa ainda',
            style: TextStyle(color: ProtoColors.muted, fontSize: 13)),
      );
    }
    // group by rodada desc
    final byRodada = <int, List<TrativaDesvio>>{};
    for (final t in d.tratativas) {
      byRodada.putIfAbsent(t.rodada, () => []).add(t);
    }
    final rodadas = byRodada.keys.toList()..sort((a, b) => b.compareTo(a));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProtoSectionTitle('Tratativas'),
        const SizedBox(height: 8),
        ...rodadas.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rodada $r',
                      style: const TextStyle(color: ProtoColors.muted, fontSize: 11, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  ...byRodada[r]!.map(_tratativaCard),
                ],
              ),
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
                    style: const TextStyle(color: ProtoColors.text, fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              ProtoPill(label: t.status, bg: bg, fg: fg),
            ]),
            const SizedBox(height: 6),
            Text(t.descricao, style: const TextStyle(color: ProtoColors.muted, fontSize: 13)),
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
                          ? Image.network(url, width: 64, height: 64, fit: BoxFit.cover,
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
        width: 64, height: 64, color: ProtoColors.surface2,
        child: const Icon(Icons.image_outlined, color: ProtoColors.muted),
      );

  List<Widget> _actions({required bool canTratar, required bool isApprover}) {
    switch (d.status) {
      case 'ABERTO':
        if (!canTratar) return [];
        return [
          _primaryButton('Abrir tratativa', () =>
              _run(() => ref.read(desvioRepositoryProvider).abrirTratativa(d.id))),
        ];
      case 'AGUARDANDO_TRATATIVA':
        if (!canTratar) return [];
        return [
          _primaryButton('Adicionar tratativa', _openAddTratativa),
          const SizedBox(height: 10),
          if (d.tratativas.any((t) => t.rodada == d.rodadaAtual && t.status == 'PENDENTE'))
            _secondaryButton('Submeter tratativas', () => _run(() => ref
                .read(desvioRepositoryProvider)
                .submeterTratativa(d.id, const SubmeterTrativaDesvioRequest()))),
        ];
      case 'AGUARDANDO_APROVACAO':
        if (!isApprover) return [];
        return [
          _primaryButton('Aprovar', () => _run(() => ref
              .read(desvioRepositoryProvider)
              .aprovar(d.id, const AprovarDesvioRequest()))),
          const SizedBox(height: 10),
          _secondaryButton('Reprovar', _openReprovar),
        ];
      default:
        return [];
    }
  }

  Widget _primaryButton(String label, VoidCallback onTap) => SizedBox(
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ProtoColors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ),
      );

  Widget _secondaryButton(String label, VoidCallback onTap) => SizedBox(
        height: 48,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: ProtoColors.borderStrong),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(color: ProtoColors.text, fontWeight: FontWeight.w800)),
        ),
      );

  Future<void> _openAddTratativa() async {
    final result = await showModalBottomSheet<_NovaTratativa>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ProtoColors.surface,
      builder: (_) => const _AddTratativaSheet(),
    );
    if (result == null) return;
    await _run(() async {
      // upload each photo as TRATATIVA, collect ids, then add tratativa
      final repo = ref.read(evidenciaRepositoryProvider);
      final ids = <String>[];
      for (final f in result.fotos) {
        final ev = await repo.uploadParaDesvio(
          d.id, f,
          EvidenciaMetadata(
              latitude: 0, longitude: 0,
              capturedAt: DateTime.now().millisecondsSinceEpoch),
          tipo: 'TRATATIVA',
        );
        ids.add(ev.id);
      }
      await ref.read(desvioRepositoryProvider).adicionarTratativa(
            d.id,
            AdicionarTrativaRequest(
              titulo: result.titulo,
              descricao: result.descricao,
              evidenciaIds: ids,
            ),
          );
    });
  }

  Future<void> _openReprovar() async {
    final pendentes =
        d.tratativas.where((t) => t.rodada == d.rodadaAtual && t.status == 'PENDENTE').toList();
    final motivos = {for (final t in pendentes) t.id: TextEditingController()};
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ProtoColors.surface,
        title: const Text('Reprovar tratativas', style: TextStyle(color: ProtoColors.text)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: pendentes
                .map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.titulo, style: const TextStyle(color: ProtoColors.text, fontSize: 13)),
                          TextField(
                            controller: motivos[t.id],
                            style: const TextStyle(color: ProtoColors.text),
                            decoration: const InputDecoration(hintText: 'Motivo'),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reprovar')),
        ],
      ),
    );
    if (ok != true) return;
    final itens = pendentes
        .map((t) => ItemReprovacao(trativaId: t.id, motivo: motivos[t.id]!.text.trim()))
        .where((i) => i.motivo.isNotEmpty)
        .toList();
    for (final c in motivos.values) {
      c.dispose();
    }
    if (itens.isEmpty) return;
    await _run(() => ref
        .read(desvioRepositoryProvider)
        .reprovar(d.id, ReprovarTrativasDesvioRequest(itens: itens)));
  }
}

class _NovaTratativa {
  final String titulo;
  final String descricao;
  final List<File> fotos;
  const _NovaTratativa(this.titulo, this.descricao, this.fotos);
}

class _AddTratativaSheet extends StatefulWidget {
  const _AddTratativaSheet();
  @override
  State<_AddTratativaSheet> createState() => _AddTratativaSheetState();
}

class _AddTratativaSheetState extends State<_AddTratativaSheet> {
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _fotos = <File>[];
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _take() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (x != null) setState(() => _fotos.add(File(x.path)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProtoSectionTitle('Nova tratativa'),
          const SizedBox(height: 12),
          TextField(
            controller: _titulo,
            style: const TextStyle(color: ProtoColors.text),
            decoration: const InputDecoration(hintText: 'Titulo'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descricao,
            maxLines: 2,
            style: const TextStyle(color: ProtoColors.text),
            decoration: const InputDecoration(hintText: 'Descricao'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            ProtoIconButton(icon: Icons.camera_alt_outlined, onTap: _take),
            const SizedBox(width: 10),
            Text('${_fotos.length} foto(s)',
                style: const TextStyle(color: ProtoColors.muted, fontSize: 12)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ProtoColors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (_titulo.text.trim().isEmpty || _descricao.text.trim().isEmpty || _fotos.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Titulo, descricao e ao menos 1 foto sao obrigatorios')));
                  return;
                }
                Navigator.pop(context,
                    _NovaTratativa(_titulo.text.trim(), _descricao.text.trim(), _fotos));
              },
              child: const Text('Salvar tratativa',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze the whole feature**

Run: `flutter analyze lib/features/ocorrencias/ lib/features/wizard/ lib/core/router/app_router.dart lib/shared/widgets/engseg_shell.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/ocorrencias/desvio_feed_page.dart lib/features/ocorrencias/desvio_detail_page.dart lib/core/router/app_router.dart lib/shared/widgets/engseg_shell.dart
git commit -m "feat(mobile): Desvio list, detail and tratativa actions (abrir/adicionar/submeter/aprovar/reprovar)"
```

---

## Phase F — Verification

### Task 14: Full test + analyze + device walkthrough

- [ ] **Step 1: Run all unit tests**

Run: `flutter test`
Expected: All pass (existing + new model/repo tests).

- [ ] **Step 2: Static analysis**

Run: `flutter analyze`
Expected: No new issues introduced by this work.

- [ ] **Step 3: Device walkthrough on Redmi Note 7**

Run: `flutter run -d f868b62` and verify end-to-end:
1. **Create Desvio (photo-first):** FAB → Desvio → capture → fill title + responsáveis + (optional) email exclusions/manuals → Registrar → lands on Desvio detail.
2. **Tratativa flow:** as responsável-tratativa, `ABERTO` → Abrir tratativa → `AGUARDANDO_TRATATIVA` → Adicionar tratativa (title, descrição, 1 photo) → Submeter → `AGUARDANDO_APROVACAO`.
3. **Approval:** as ENGENHEIRO/responsável-desvio → Aprovar → `CONCLUIDO`; and on another desvio → Reprovar with motivo → reopens a new round.
4. **Create NC (photo-first):** FAB → NC → capture → severidade/probabilidade, norma, responsáveis, descrição → Registrar → lands on existing NC detail with the photo under Evidências.
5. **Desvios tab** lists desvios for the current workspace and opens detail.

- [ ] **Step 4: Cross-check on web**

Open the web app for the same estabelecimento and confirm the created NC/Desvio and tratativa actions appear with correct status, responsáveis and evidências.

---

## Self-review notes (carried into execution)

- **VERIFY at runtime:** `emailsPadrao` empresa id (`workspace.empresa.id` vs `empresaFilha.id`). If list comes empty/403, editor still works with manual emails (provider already swallows errors).
- **Permission edge:** desvio evidence upload is TECNICO/ENGENHEIRO only; an EXTERNO tratativa-responsável will get a 403 when adding a tratativa photo — surfaced via the snackbar in `_run`.
- **GPS optional:** if location permission is denied, `_meta` falls back to lat/lon `0` (backend accepts null/zero); acceptable for MVP.
- **Nav bar tradeoff (Task 12, Step 3):** default removes the Dashboard tab to fit Desvios; confirm with product owner.
- **Action responses:** tratativa actions return `void`; UI re-fetches via `desvioDetailProvider` invalidation, so we never depend on the action response body shape.
