import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';

import '../../helpers/golden.dart';

/// Peraga "Controls Row" di Figma (node 6:52): judul kecil + kotak varian.
class _Specimen extends StatelessWidget {
  const _Specimen({
    required this.title,
    required this.padding,
    required this.child,
  });

  final String title;
  final double padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.s12,
      children: [
        AppLabelText(
          title,
          style: AppText.labelSmall.copyWith(color: AppColors.gray),
        ),
        Padding(padding: EdgeInsets.all(padding), child: child),
      ],
    );
  }
}

void main() {
  testWidgets('golden: Checkbox, Switch, Chip, Badge sama dengan Figma '
      '(node 6:52)', (tester) async {
    await pumpGolden(
      tester,
      size: const Size(761, 114),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 48,
        children: [
          _Specimen(
            title: 'Checkbox — State',
            padding: AppSpace.s20,
            child: Row(
              spacing: AppSpace.s16,
              children: [
                AppCheckbox(value: false, onChanged: (_) {}),
                AppCheckbox(value: true, onChanged: (_) {}),
              ],
            ),
          ),
          _Specimen(
            title: 'Switch — State',
            padding: AppSpace.s20,
            child: Row(
              spacing: AppSpace.s16,
              children: [
                AppSwitch(value: false, onChanged: (_) {}),
                AppSwitch(value: true, onChanged: (_) {}),
              ],
            ),
          ),
          _Specimen(
            title: 'Chip — State (filter)',
            padding: AppSpace.s20,
            child: Row(
              spacing: AppSpace.s16,
              children: [
                AppChip(label: 'Semua', selected: false, onTap: () {}),
                AppChip(label: 'Semua', selected: true, onTap: () {}),
              ],
            ),
          ),
          const _Specimen(
            title: 'Badge — Type (status)',
            padding: AppSpace.s16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.s12,
              children: [
                Row(
                  spacing: AppSpace.s12,
                  children: [
                    AppBadge(label: 'Status'),
                    AppBadge(label: 'Status', type: AppBadgeType.success),
                  ],
                ),
                Row(
                  spacing: AppSpace.s12,
                  children: [
                    AppBadge(label: 'Status', type: AppBadgeType.warning),
                    AppBadge(label: 'Status', type: AppBadgeType.danger),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await expectLater(
      find.byKey(goldenKey),
      matchesGoldenFile('goldens/app_controls.png'),
    );
  });

  testWidgets('Checkbox 24×24 dan mengirim nilai baru', (tester) async {
    bool? value;
    await tester.pumpWidget(
      wrapForTest(AppCheckbox(value: false, onChanged: (v) => value = v)),
    );
    expect(tester.getSize(find.byType(AppCheckbox)), const Size.square(24));

    await tester.tap(find.byType(AppCheckbox));
    expect(value, isTrue);
  });

  testWidgets('Switch 46×26 dan mengirim nilai baru', (tester) async {
    bool? value;
    await tester.pumpWidget(
      wrapForTest(AppSwitch(value: true, onChanged: (v) => value = v)),
    );
    expect(tester.getSize(find.byType(AppSwitch)), const Size(46, 26));

    await tester.tap(find.byType(AppSwitch));
    expect(value, isFalse);
  });

  testWidgets('Chip kapital, tinggi 34, dan bisa diketuk', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrapForTest(
        AppChip(label: 'Hari ini', selected: false, onTap: () => taps++),
      ),
    );
    expect(find.text('HARI INI'), findsOneWidget);
    expect(tester.getSize(find.byType(AppChip)).height, 34);

    await tester.tap(find.byType(AppChip));
    expect(taps, 1);
  });

  testWidgets('Badge kapital dengan warna status', (tester) async {
    await tester.pumpWidget(
      wrapForTest(
        const AppBadge(label: 'Terlambat', type: AppBadgeType.danger),
      ),
    );
    final text = tester.widget<Text>(find.text('TERLAMBAT'));
    expect(text.style?.color, AppColors.danger);
    expect(tester.getSize(find.byType(AppBadge)).height, 22);
  });
}
