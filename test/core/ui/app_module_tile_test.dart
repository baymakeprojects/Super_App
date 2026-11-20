import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';

import '../../helpers/golden.dart';

/// Lebar instance di set Figma 257:252.
const double _tileWidth = 180;

void main() {
  testWidgets('golden Module Tile Default dan Segera (set 257:252)', (
    tester,
  ) async {
    await pumpGolden(
      tester,
      size: const Size(408, 166),
      child: const Padding(
        padding: EdgeInsets.all(AppSpace.s16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpace.s16,
          children: [
            SizedBox(
              width: _tileWidth,
              child: AppModuleTile(
                icon: AppIcons.learn,
                title: 'Belajar',
                caption: 'Roadmap Flutter · 42%',
              ),
            ),
            SizedBox(
              width: _tileWidth,
              child: AppModuleTile(
                icon: AppIcons.learn,
                title: 'Belajar',
                state: AppModuleTileState.segera,
              ),
            ),
          ],
        ),
      ),
    );
    await expectLater(
      find.byKey(goldenKey),
      matchesGoldenFile('goldens/app_module_tile.png'),
    );
  });

  testWidgets('tile Segera tidak bisa diketuk', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: _tileWidth,
            child: AppModuleTile(
              icon: AppIcons.timer,
              title: 'Fokus',
              state: AppModuleTileState.segera,
              onTap: () => tapped++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('SEGERA'), findsOneWidget);
    await tester.tap(find.text('Fokus'));
    expect(tapped, 0);
  });

  testWidgets('tile normal bisa diketuk dan menampilkan caption', (
    tester,
  ) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: _tileWidth,
            child: AppModuleTile(
              icon: AppIcons.timer,
              title: 'Fokus',
              caption: '2 j 30 m fokus hari ini',
              onTap: () => tapped++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('2 j 30 m fokus hari ini'), findsOneWidget);
    expect(find.text('SEGERA'), findsNothing);
    await tester.tap(find.text('Fokus'));
    expect(tapped, 1);
  });
}
