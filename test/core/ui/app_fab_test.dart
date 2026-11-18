import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/ui/ui.dart';

import '../../helpers/golden.dart';

void main() {
  testWidgets('golden: FAB sama dengan Figma (node 6:27)', (tester) async {
    await pumpGolden(
      tester,
      size: const Size.square(AppFab.size),
      child: AppFab(onPressed: () {}, semanticLabel: 'Tambah'),
    );

    await expectLater(
      find.byKey(goldenKey),
      matchesGoldenFile('goldens/app_fab.png'),
    );
  });

  testWidgets('56×56 dan bisa ditekan', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrapForTest(AppFab(onPressed: () => taps++, semanticLabel: 'Tambah')),
    );

    expect(tester.getSize(find.byType(AppFab)), const Size.square(56));
    await tester.tap(find.byType(AppFab));
    expect(taps, 1);
    expect(find.bySemanticsLabel('Tambah'), findsOneWidget);
  });
}
