import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';

import '../../helpers/golden.dart';

// Ukuran instance di frame peraga Figma.
const double _itemWidth = 372;
const double _phoneWidth = 412;
const double _pickerWidth = 364;

Future<void> _golden(
  WidgetTester tester,
  String name,
  Size size,
  Widget child,
) async {
  await pumpGolden(tester, size: size, child: child);
  await expectLater(
    find.byKey(goldenKey),
    matchesGoldenFile('goldens/$name.png'),
  );
}

/// Frame peraga Figma: padding 20 di sekeliling varian.
Widget _frame(Widget child) =>
    Padding(padding: const EdgeInsets.all(AppSpace.s20), child: child);

void main() {
  testWidgets('Task Item Default dan Done (node 8:75)', (tester) async {
    Widget item({required bool done}) => SizedBox(
      width: _itemWidth,
      child: AppTaskItem(
        title: 'Laporan praktikum modul 5',
        meta: 'Pemrograman Mobile · 23.59',
        done: done,
        badge: done
            ? const AppBadge(label: 'Selesai', type: AppBadgeType.success)
            : const AppBadge(label: 'Hari ini', type: AppBadgeType.warning),
        onDoneChanged: (_) {},
      ),
    );

    await _golden(
      tester,
      'app_task_item',
      const Size(800, 116),
      _frame(
        Row(
          spacing: AppSpace.s16,
          children: [item(done: false), item(done: true)],
        ),
      ),
    );
  });

  testWidgets('Class Item Upcoming, Now, Done (node 9:69)', (tester) async {
    Widget item(AppClassItemState state) => SizedBox(
      width: _itemWidth,
      child: AppClassItem(
        start: '08.00',
        end: '09.40',
        course: 'Pemrograman Mobile',
        meta: 'Ruang 301 · Bu Rina',
        state: state,
      ),
    );

    await _golden(
      tester,
      'app_class_item',
      const Size(800, 260),
      _frame(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpace.s16,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.s16,
              children: [
                item(AppClassItemState.upcoming),
                item(AppClassItemState.now),
              ],
            ),
            item(AppClassItemState.done),
          ],
        ),
      ),
    );
  });

  testWidgets('Day Pill Default dan Selected (node 9:79)', (tester) async {
    await _golden(
      tester,
      'app_day_pill',
      const Size(160, 106),
      _frame(
        Row(
          spacing: AppSpace.s16,
          children: [
            for (final selected in [false, true])
              AppDayPill(
                day: 'Jum',
                date: '7',
                selected: selected,
                onTap: () {},
              ),
          ],
        ),
      ),
    );
  });

  testWidgets('Segmented Control First dan Second (node 21:62)', (
    tester,
  ) async {
    await _golden(
      tester,
      'app_segmented_control',
      const Size(_phoneWidth, 156),
      _frame(
        SizedBox(
          width: _itemWidth,
          child: Column(
            spacing: AppSpace.s16,
            children: [
              for (final index in [0, 1])
                AppSegmentedControl(
                  firstLabel: 'Pengeluaran',
                  secondLabel: 'Pemasukan',
                  selectedIndex: index,
                  onChanged: (_) {},
                ),
            ],
          ),
        ),
      ),
    );
  });

  testWidgets('Select (node 21:65)', (tester) async {
    await _golden(
      tester,
      'app_select',
      const Size(_itemWidth, 82),
      SizedBox(
        width: _itemWidth,
        child: AppSelect(
          label: 'Mata kuliah',
          value: 'Pemrograman Mobile',
          onTap: () {},
        ),
      ),
    );
  });

  testWidgets('Checklist Item Default dan Done (node 21:112)', (tester) async {
    await _golden(
      tester,
      'app_checklist_item',
      const Size(380, 136),
      _frame(
        SizedBox(
          width: 340,
          child: Column(
            spacing: AppSpace.s16,
            children: [
              for (final done in [false, true])
                AppChecklistItem(
                  label: 'Tulis analisis',
                  done: done,
                  onChanged: (_) {},
                ),
            ],
          ),
        ),
      ),
    );
  });

  testWidgets('Action Bar Single dan Double (node 21:123)', (tester) async {
    await _golden(
      tester,
      'app_action_bar',
      const Size(452, 234),
      _frame(
        SizedBox(
          width: _phoneWidth,
          child: Column(
            spacing: AppSpace.s16,
            children: [
              AppActionBar(primaryLabel: 'Simpan', onPrimaryPressed: () {}),
              AppActionBar(
                primaryLabel: 'Simpan',
                onPrimaryPressed: () {},
                secondaryLabel: 'Hapus',
                onSecondaryPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  });

  testWidgets('Overlay Header Sheet dan Dialog (node 49:154)', (tester) async {
    Widget header(AppOverlayHeaderType type, double width) => SizedBox(
      width: width,
      child: AppOverlayHeader(
        title: 'Judul pop-up',
        subtitle: 'Keterangan singkat',
        onClose: () {},
        type: type,
      ),
    );

    await _golden(
      tester,
      'app_overlay_header',
      const Size(560, 216),
      _frame(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpace.s24,
          children: [
            header(AppOverlayHeaderType.sheet, _phoneWidth),
            header(AppOverlayHeaderType.dialog, 520),
          ],
        ),
      ),
    );
  });

  testWidgets('Option Item Default dan Selected (node 49:174)', (tester) async {
    await _golden(
      tester,
      'app_option_item',
      const Size(404, 190),
      _frame(
        SizedBox(
          width: _pickerWidth,
          child: Column(
            spacing: AppSpace.s12,
            children: [
              for (final selected in [false, true])
                AppOptionItem(
                  title: 'Pilihan',
                  caption: 'Keterangan',
                  icon: AppIcons.wallet,
                  selected: selected,
                  onTap: () {},
                ),
            ],
          ),
        ),
      ),
    );
  });

  testWidgets('Day Cell semua keadaan (node 49:188)', (tester) async {
    await _golden(
      tester,
      'app_day_cell',
      const Size(288, 80),
      _frame(
        Row(
          spacing: AppSpace.s12,
          children: [
            for (final state in AppDayCellState.values)
              AppDayCell(day: '6', state: state),
          ],
        ),
      ),
    );
  });

  testWidgets('Date Picker November 2026 (node 49:191)', (tester) async {
    await _golden(
      tester,
      'app_date_picker',
      const Size(_pickerWidth, 332),
      SizedBox(
        width: _pickerWidth,
        child: AppDatePicker(
          today: DateTime(2026, 11, 6),
          selected: DateTime(2026, 11, 10),
          onSelected: (_) {},
        ),
      ),
    );
  });

  testWidgets('Time Picker 23.59 (node 49:309)', (tester) async {
    await _golden(
      tester,
      'app_time_picker',
      const Size(_pickerWidth, 122),
      SizedBox(
        width: _pickerWidth,
        child: AppTimePicker(hour: 23, minute: 59, onChanged: (_, _) {}),
      ),
    );
  });

  testWidgets('Snackbar (node 65:187)', (tester) async {
    await _golden(
      tester,
      'app_snackbar',
      const Size(_itemWidth, 46),
      SizedBox(
        width: _itemWidth,
        child: AppSnackbar(
          message: 'Tugas dihapus',
          actionLabel: 'Urungkan',
          onAction: () {},
        ),
      ),
    );
  });
}
