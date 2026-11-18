import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';

import '../../helpers/golden.dart';

Color? _labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color;

void main() {
  testWidgets('golden: Input Default, Focus, Error sama dengan Figma '
      '(node 6:51)', (tester) async {
    Widget input(AppInputState state) => SizedBox(
      width: 360,
      child: AppInput(
        label: 'Judul tugas',
        placeholder: 'Contoh: laporan praktikum',
        errorText: state == AppInputState.error ? 'Wajib diisi' : null,
        previewState: state,
      ),
    );

    await pumpGolden(
      tester,
      size: const Size(1152, 146),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpace.s16,
          children: [for (final state in AppInputState.values) input(state)],
        ),
      ),
    );

    await expectLater(
      find.byKey(goldenKey),
      matchesGoldenFile('goldens/app_input.png'),
    );
  });

  testWidgets('tinggi Default 82 dan Error 106 seperti Figma', (tester) async {
    await tester.pumpWidget(
      wrapForTest(
        const SizedBox(
          width: 360,
          child: AppInput(label: 'Judul tugas', placeholder: 'Contoh'),
        ),
      ),
    );
    expect(tester.getSize(find.byType(AppInput)).height, 82);

    await tester.pumpWidget(
      wrapForTest(
        const SizedBox(
          width: 360,
          child: AppInput(
            label: 'Judul tugas',
            placeholder: 'Contoh',
            errorText: 'Wajib diisi',
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(AppInput)).height, 106);
  });

  testWidgets('diketuk = Focus oranye, lalu teks bisa diketik', (tester) async {
    String? typed;
    await tester.pumpWidget(
      wrapForTest(
        SizedBox(
          width: 360,
          child: AppInput(
            label: 'Judul tugas',
            placeholder: 'Contoh',
            onChanged: (value) => typed = value,
          ),
        ),
      ),
    );
    expect(_labelColor(tester, 'JUDUL TUGAS'), AppColors.lightGray);

    await tester.tap(find.byType(AppInput));
    await tester.pump();
    expect(_labelColor(tester, 'JUDUL TUGAS'), AppColors.accentText);

    await tester.enterText(find.byType(TextField), 'Laporan');
    expect(typed, 'Laporan');
  });

  testWidgets('errorText = label dan pesan merah', (tester) async {
    await tester.pumpWidget(
      wrapForTest(
        const SizedBox(
          width: 360,
          child: AppInput(label: 'Judul tugas', errorText: 'Wajib diisi'),
        ),
      ),
    );
    expect(_labelColor(tester, 'JUDUL TUGAS'), AppColors.danger);
    expect(_labelColor(tester, 'Wajib diisi'), AppColors.danger);
  });
}
