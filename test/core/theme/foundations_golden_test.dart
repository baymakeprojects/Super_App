import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'foundations_sheet.dart';

void main() {
  testWidgets('Halaman token sama dengan Foundations Figma (node 4:4)', (
    tester,
  ) async {
    tester.view
      ..physicalSize = FoundationsSheet.frameSize
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(child: FoundationsSheet()),
      ),
    );

    await expectLater(
      find.byType(FoundationsSheet),
      matchesGoldenFile('goldens/foundations.png'),
    );
  });
}
