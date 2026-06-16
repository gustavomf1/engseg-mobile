import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:engseg_mobile/features/auth/model/login_response.dart';
import 'package:engseg_mobile/features/auth/provider/auth_provider.dart';
import 'package:engseg_mobile/shared/widgets/eng_auth_image.dart';
import 'package:engseg_mobile/shared/widgets/eng_cover_card.dart';

class MockAuthNotifier extends AsyncNotifier<LoginResponse?>
    with Mock
    implements AuthNotifier {
  @override
  Future<LoginResponse?> build() async => const LoginResponse(
        id: 'u1', token: 'tok', nome: 'T', email: 't@t.com',
        perfil: 'ENGENHEIRO', isAdmin: false,
      );
}

Widget _wrap(Widget child) => ProviderScope(
      overrides: [authProvider.overrideWith(MockAuthNotifier.new)],
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('exibe EngAuthImage quando evidência é imagem', (tester) async {
    await tester.pumpWidget(_wrap(EngCoverCard(
      id: 'nc-1',
      titulo: 'NC Teste',
      coverUrl: 'http://host/api/evidencias/ev-1/download',
      hasImageCover: true,
      hasAnyCover: true,
      pills: const [],
      meta: 'Obra Central',
      onTap: () {},
    )));
    await tester.pump();
    expect(find.byType(EngAuthImage), findsOneWidget);
  });

  testWidgets('exibe fallback documento quando evidência não é imagem',
      (tester) async {
    await tester.pumpWidget(_wrap(EngCoverCard(
      id: 'nc-2',
      titulo: 'NC PDF',
      coverUrl: 'http://host/api/evidencias/ev-2/download',
      hasImageCover: false,
      hasAnyCover: true,
      pills: const [],
      meta: 'Obra B',
      onTap: () {},
    )));
    await tester.pump();
    expect(find.byIcon(Icons.insert_drive_file_outlined), findsOneWidget);
    expect(find.byType(EngAuthImage), findsNothing);
  });

  testWidgets('exibe fallback neutro quando sem evidência', (tester) async {
    await tester.pumpWidget(_wrap(EngCoverCard(
      id: 'nc-3',
      titulo: 'NC Sem Foto',
      coverUrl: null,
      hasImageCover: false,
      hasAnyCover: false,
      pills: const [],
      meta: 'Obra C',
      onTap: () {},
    )));
    await tester.pump();
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    expect(find.byType(EngAuthImage), findsNothing);
  });
}
