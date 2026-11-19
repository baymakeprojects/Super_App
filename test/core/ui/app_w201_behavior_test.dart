import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';

import '../../helpers/golden.dart';

Widget _wide(Widget child) => wrapForTest(SizedBox(width: 372, child: child));

void main() {
  group('ukuran sama dengan Figma', () {
    testWidgets('Task 76, Class 76/102, Day Pill 66, Segmented 50, '
        'Select 82, Checklist 40, Action Bar 89, Overlay 76, Option 68/70, '
        'Snackbar 46', (tester) async {
      Future<double> heightOf(Widget child, Type type) async {
        await tester.pumpWidget(_wide(child));
        return tester.getSize(find.byType(type)).height;
      }

      expect(
        await heightOf(
          const AppTaskItem(title: 'Judul', meta: 'Meta', done: false),
          AppTaskItem,
        ),
        76,
      );
      for (final (state, height) in [
        (AppClassItemState.upcoming, 76.0),
        (AppClassItemState.now, 102.0),
      ]) {
        expect(
          await heightOf(
            AppClassItem(
              start: '08.00',
              end: '09.40',
              course: 'Kuliah',
              meta: 'Ruang',
              state: state,
            ),
            AppClassItem,
          ),
          height,
        );
      }
      expect(
        await heightOf(
          AppDayPill(day: 'Jum', date: '7', selected: false, onTap: () {}),
          AppDayPill,
        ),
        66,
      );
      expect(
        await heightOf(
          AppSegmentedControl(
            firstLabel: 'A',
            secondLabel: 'B',
            selectedIndex: 0,
            onChanged: (_) {},
          ),
          AppSegmentedControl,
        ),
        50,
      );
      expect(
        await heightOf(
          AppSelect(label: 'Label', value: 'Nilai', onTap: () {}),
          AppSelect,
        ),
        82,
      );
      expect(
        await heightOf(
          AppChecklistItem(label: 'Item', done: false, onChanged: (_) {}),
          AppChecklistItem,
        ),
        40,
      );
      expect(
        await heightOf(
          AppActionBar(primaryLabel: 'Simpan', onPrimaryPressed: () {}),
          AppActionBar,
        ),
        89,
      );
      expect(
        await heightOf(
          AppOverlayHeader(title: 'Judul', subtitle: 'Sub', onClose: () {}),
          AppOverlayHeader,
        ),
        76,
      );
      for (final (selected, height) in [(false, 68.0), (true, 70.0)]) {
        expect(
          await heightOf(
            AppOptionItem(
              title: 'Pilihan',
              caption: 'Keterangan',
              icon: AppIcons.wallet,
              selected: selected,
              onTap: () {},
            ),
            AppOptionItem,
          ),
          height,
        );
      }
      expect(
        await heightOf(
          const AppSnackbar(message: 'Tugas dihapus', actionLabel: 'Urungkan'),
          AppSnackbar,
        ),
        46,
      );
    });
  });

  group('perilaku', () {
    testWidgets('Task Item: checkbox dan baris punya aksi sendiri', (
      tester,
    ) async {
      bool? done;
      var opened = 0;
      await tester.pumpWidget(
        _wide(
          AppTaskItem(
            title: 'Laporan',
            meta: 'Meta',
            done: false,
            onDoneChanged: (v) => done = v,
            onTap: () => opened++,
          ),
        ),
      );

      await tester.tap(find.byType(AppCheckbox));
      expect(done, isTrue);
      expect(opened, 0);

      await tester.tap(find.text('Laporan'));
      expect(opened, 1);
    });

    testWidgets('Task Item Done: judul abu', (tester) async {
      await tester.pumpWidget(
        _wide(const AppTaskItem(title: 'Laporan', meta: 'Meta', done: true)),
      );
      final title = tester.widget<Text>(find.text('Laporan'));
      expect(title.style?.color, AppColors.gray);
    });

    testWidgets('Segmented Control mengirim indeks', (tester) async {
      int? index;
      await tester.pumpWidget(
        _wide(
          AppSegmentedControl(
            firstLabel: 'Pengeluaran',
            secondLabel: 'Pemasukan',
            selectedIndex: 0,
            onChanged: (i) => index = i,
          ),
        ),
      );
      await tester.tap(find.text('PEMASUKAN'));
      expect(index, 1);
    });

    testWidgets('Select tanpa nilai menampilkan placeholder abu', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _wide(
          AppSelect(
            label: 'Dompet',
            value: null,
            placeholder: 'Pilih dompet',
            onTap: () => taps++,
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('Pilih dompet'));
      expect(text.style?.color, AppColors.gray);

      await tester.tap(find.byType(AppSelect));
      expect(taps, 1);
    });

    testWidgets('Checklist Item: ketuk baris membalik centang', (tester) async {
      bool? done;
      await tester.pumpWidget(
        _wide(
          AppChecklistItem(
            label: 'Bab 1',
            done: true,
            onChanged: (v) => done = v,
          ),
        ),
      );
      await tester.tap(find.text('Bab 1'));
      expect(done, isFalse);
    });

    testWidgets('Action Bar Double: dua tombol bekerja', (tester) async {
      final pressed = <String>[];
      await tester.pumpWidget(
        _wide(
          AppActionBar(
            primaryLabel: 'Tandai selesai',
            onPrimaryPressed: () => pressed.add('primary'),
            secondaryLabel: 'Hapus',
            onSecondaryPressed: () => pressed.add('secondary'),
          ),
        ),
      );
      await tester.tap(find.text('HAPUS'));
      await tester.tap(find.text('TANDAI SELESAI'));
      expect(pressed, ['secondary', 'primary']);
    });

    testWidgets('Overlay Header: tombol tutup dan tanpa tombol tutup', (
      tester,
    ) async {
      var closed = 0;
      await tester.pumpWidget(
        _wide(AppOverlayHeader(title: 'Judul', onClose: () => closed++)),
      );
      await tester.tap(find.bySemanticsLabel('Tutup'));
      expect(closed, 1);

      await tester.pumpWidget(_wide(const AppOverlayHeader(title: 'Hapus?')));
      expect(find.bySemanticsLabel('Tutup'), findsNothing);
    });

    testWidgets('Option Item bisa dipilih', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wide(
          AppOptionItem(title: 'Tunai', selected: false, onTap: () => taps++),
        ),
      );
      await tester.tap(find.text('Tunai'));
      expect(taps, 1);
    });

    testWidgets('Date Picker: 6 baris, pindah bulan, pilih tanggal', (
      tester,
    ) async {
      DateTime? picked;
      await tester.pumpWidget(
        _wide(
          AppDatePicker(
            today: DateTime(2026, 11, 6),
            selected: null,
            onSelected: (d) => picked = d,
          ),
        ),
      );

      expect(find.text('November 2026'), findsOneWidget);
      expect(find.byType(AppDayCell), findsNWidgets(42));
      // 6 November = hari ini.
      final today = tester
          .widgetList<AppDayCell>(find.byType(AppDayCell))
          .where((c) => c.state == AppDayCellState.today);
      expect(today.single.day, '6');

      await tester.tap(find.bySemanticsLabel('Bulan berikutnya'));
      await tester.pump();
      expect(find.text('Desember 2026'), findsOneWidget);
      // Februari 2026 cukup 4 minggu, tapi tetap 6 baris.
      expect(find.byType(AppDayCell), findsNWidgets(42));

      await tester.tap(find.text('24').first);
      expect(picked, DateTime(2026, 12, 24));

      await tester.tap(find.bySemanticsLabel('Bulan sebelumnya'));
      await tester.tap(find.bySemanticsLabel('Bulan sebelumnya'));
      await tester.pump();
      expect(find.text('Oktober 2026'), findsOneWidget);
    });

    testWidgets('Date Picker: tanggal bulan lain tidak bisa dipilih', (
      tester,
    ) async {
      DateTime? picked;
      await tester.pumpWidget(
        _wide(
          AppDatePicker(
            today: DateTime(2026, 11, 6),
            selected: null,
            onSelected: (d) => picked = d,
          ),
        ),
      );
      // Baris pertama November 2026 dimulai 26 Oktober (muted).
      await tester.tap(find.text('26').first);
      expect(picked, isNull);
    });

    testWidgets('Time Picker: ketuk, geser, dan berputar 23 → 00', (
      tester,
    ) async {
      var hour = 23;
      var minute = 59;
      Future<void> pump() => tester.pumpWidget(
        _wide(
          AppTimePicker(
            hour: hour,
            minute: minute,
            onChanged: (h, m) {
              hour = h;
              minute = m;
            },
          ),
        ),
      );
      await pump();

      // Ketuk angka bawah jam: 23 → 00.
      await tester.tap(find.text('00').first);
      expect(hour, 0);
      expect(minute, 59);

      // Ketuk angka atas menit: 59 → 58.
      await pump();
      await tester.tap(find.text('58'));
      expect(minute, 58);

      // Geser kolom jam ke atas dua langkah: 00 → 02.
      await pump();
      await tester.drag(find.text('00').first, const Offset(0, -72));
      expect(hour, 2);
    });

    testWidgets('showAppSnackbar: tampil, Urungkan, hilang setelah 4 detik', (
      tester,
    ) async {
      var undone = 0;
      await tester.pumpWidget(
        wrapForTest(
          Builder(
            builder: (context) => AppButton(
              label: 'Hapus',
              expand: false,
              onPressed: () => showAppSnackbar(
                context,
                message: 'Tugas dihapus',
                actionLabel: 'Urungkan',
                onAction: () => undone++,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('HAPUS'));
      await tester.pumpAndSettle();
      expect(find.text('Tugas dihapus'), findsOneWidget);

      await tester.tap(find.text('URUNGKAN'));
      await tester.pumpAndSettle();
      expect(undone, 1);
      expect(find.text('Tugas dihapus'), findsNothing);

      await tester.tap(find.text('HAPUS'));
      await tester.pumpAndSettle();
      expect(find.text('Tugas dihapus'), findsOneWidget);
      await tester.pump(appSnackbarDuration);
      await tester.pumpAndSettle();
      expect(find.text('Tugas dihapus'), findsNothing);
    });
  });
}
