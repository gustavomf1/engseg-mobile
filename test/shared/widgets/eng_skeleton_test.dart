import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:engseg_mobile/shared/widgets/eng_skeleton.dart';

void main() {
  testWidgets('EngSkeleton renderiza Container', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: EngSkeleton(height: 40))),
    );
    await tester.pump(Duration.zero); // fire flutter_animate startup timer
    expect(find.byType(Container), findsWidgets);
    await tester.pumpWidget(const SizedBox()); // dispose AnimationController
    await tester.pump();
  });

  testWidgets('CoverCardSkeleton renderiza múltiplos EngSkeleton', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CoverCardSkeleton())),
    );
    await tester.pump(Duration.zero);
    expect(find.byType(EngSkeleton), findsWidgets);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
