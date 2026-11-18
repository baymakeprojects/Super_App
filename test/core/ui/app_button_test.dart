import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';

import '../../helpers/golden.dart';

BoxDecoration _decorationOf(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(AppButton),
      matching: find.byType(Container),
    ),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('golden: Button Style × State sama dengan Figma (node 6:24)', (
    tester,
  ) async {
    Widget button(AppButtonStyle style, AppButtonState state) => AppButton(
      label: 'Simpan →',
      style: style,
      expand: false,
      onPressed: () {},
      previewState: state,
    );

    await pumpGolden(
      tester,
      size: const Size(568, 228),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpace.s16,
          children: [
            for (final style in [AppButtonStyle.primary, AppButtonStyle.ghost])
              Row(
                spacing: AppSpace.s16,
                children: [
                  for (final state in AppButtonState.values)
                    button(style, state),
                ],
              ),
            button(AppButtonStyle.danger, AppButtonState.normal),
          ],
        ),
      ),
    );

    await expectLater(
      find.byKey(goldenKey),
      matchesGoldenFile('goldens/app_button.png'),
    );
  });

  testWidgets('tinggi 52, label kapital, dan ditekan memanggil onPressed', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      wrapForTest(AppButton(label: 'Simpan tugas', onPressed: () => taps++)),
    );

    expect(find.text('SIMPAN TUGAS'), findsOneWidget);
    expect(tester.getSize(find.byType(AppButton)).height, 52);

    await tester.tap(find.byType(AppButton));
    expect(taps, 1);
  });

  testWidgets('melebar penuh secara bawaan', (tester) async {
    await tester.pumpWidget(
      wrapForTest(
        SizedBox(
          width: 300,
          child: AppButton(label: 'Simpan', onPressed: () {}),
        ),
      ),
    );
    expect(tester.getSize(find.byType(AppButton)).width, 300);
  });

  testWidgets('Primary berubah jadi Red saat ditekan', (tester) async {
    await tester.pumpWidget(
      wrapForTest(AppButton(label: 'Simpan', onPressed: () {})),
    );
    expect(_decorationOf(tester).color, AppColors.brandingOrange);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AppButton)),
    );
    await tester.pump();
    expect(_decorationOf(tester).color, AppColors.gradientRed);

    await gesture.up();
    await tester.pump();
    expect(_decorationOf(tester).color, AppColors.brandingOrange);
  });

  testWidgets('onPressed null = Disabled', (tester) async {
    await tester.pumpWidget(
      wrapForTest(const AppButton(label: 'Simpan', onPressed: null)),
    );
    expect(_decorationOf(tester).color, AppColors.surfaceCard);
  });
}
