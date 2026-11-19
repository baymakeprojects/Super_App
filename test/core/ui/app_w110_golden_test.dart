import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';

import '../../helpers/golden.dart';

Future<void> _golden(
  WidgetTester tester,
  String name,
  Size size,
  Widget child,
) async {
  await pumpGolden(
    tester,
    size: size,
    child: Padding(padding: const EdgeInsets.all(AppSpace.s20), child: child),
  );
  await expectLater(
    find.byKey(goldenKey),
    matchesGoldenFile('goldens/$name.png'),
  );
}

void main() {
  testWidgets('Code Cell Empty, Focus, Filled, Error (node 229:241)', (
    tester,
  ) async {
    await _golden(
      tester,
      'app_code_cell',
      const Size(300, 104),
      Row(
        spacing: AppSpace.s8,
        children: [
          for (final state in AppCodeCellState.values)
            SizedBox(
              width: 52,
              child: AppCodeCell(state: state, digit: '4'),
            ),
        ],
      ),
    );
  });

  testWidgets('Keypad dengan dan tanpa sidik jari (node 49:323)', (
    tester,
  ) async {
    Widget keypad({required bool fingerprint}) => SizedBox(
      width: 364,
      child: AppKeypad(
        onDigit: (_) {},
        onDelete: () {},
        showFingerprint: fingerprint,
      ),
    );

    await _golden(
      tester,
      'app_keypad',
      const Size(800, 332),
      Row(
        spacing: AppSpace.s32,
        children: [keypad(fingerprint: true), keypad(fingerprint: false)],
      ),
    );
  });

  testWidgets('PIN, Page Indicator, Logo (H06, 62:1799, 63:2011)', (
    tester,
  ) async {
    await _golden(
      tester,
      'app_pin_page_logo',
      const Size(520, 96),
      const Row(
        spacing: AppSpace.s24,
        children: [
          AppPinDots(filled: 2),
          AppPageIndicator(page: 1),
          AppPageIndicator(page: 4),
          AppLogoMark(),
          AppLogoMark(size: AppLogoMarkSize.large),
        ],
      ),
    );
  });

  testWidgets('List Row Chevron, Switch, Value (node 21:99)', (tester) async {
    Widget row(Widget trailing) => SizedBox(
      width: 372,
      child: AppListRow(
        icon: AppIcons.lock,
        title: 'Kunci sidik jari',
        subtitle: 'Minta sidik jari saat app dibuka',
        trailing: trailing,
      ),
    );

    await _golden(
      tester,
      'app_list_row',
      const Size(412, 240),
      Column(
        spacing: AppSpace.s8,
        children: [
          row(const AppListRowChevron()),
          row(AppListRowSwitch(value: true, onChanged: (_) {})),
          row(const AppListRowValue('08.12')),
        ],
      ),
    );
  });

  testWidgets('Skeleton E7: daftar memuat (68:2334)', (tester) async {
    await _golden(
      tester,
      'app_skeleton_list',
      const Size(412, 300),
      const SizedBox(width: 372, child: AppSkeletonList()),
    );
  });

  testWidgets('Keypad mengirim angka, hapus, dan sidik jari', (tester) async {
    final typed = <String>[];
    var deleted = 0;
    var fingerprint = 0;
    await tester.pumpWidget(
      wrapForTest(
        SizedBox(
          width: 364,
          child: AppKeypad(
            onDigit: typed.add,
            onDelete: () => deleted++,
            onFingerprint: () => fingerprint++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('7'));
    await tester.tap(find.text('0'));
    await tester.tap(find.bySemanticsLabel('Hapus'));
    await tester.tap(find.bySemanticsLabel('Sidik jari'));
    expect(typed, ['7', '0']);
    expect(deleted, 1);
    expect(fingerprint, 1);
  });
}
