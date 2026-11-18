import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';

import '../../helpers/golden.dart';

/// Ukuran instance di frame peraga Figma.
const double _cardWidth = 380;
const double _statCardWidth = 182;
const double _phoneWidth = 412;
const double _sectionHeaderWidth = 372;
const double _navItemWidth = 80;

Future<void> _expectGolden(String name) =>
    expectLater(find.byKey(goldenKey), matchesGoldenFile('goldens/$name.png'));

void main() {
  group('golden sama dengan Figma', () {
    testWidgets('Card (node 7:11)', (tester) async {
      await pumpGolden(
        tester,
        size: const Size(_cardWidth, 136),
        child: const SizedBox(
          width: _cardWidth,
          child: AppCard(
            eyebrow: '[01] Label',
            title: 'Judul kartu',
            body: 'Isi kartu singkat, maksimal dua baris supaya tetap ringkas.',
          ),
        ),
      );
      await _expectGolden('app_card');
    });

    testWidgets('Stat Card (node 7:17)', (tester) async {
      await pumpGolden(
        tester,
        size: const Size(_statCardWidth, 110),
        child: const SizedBox(
          width: _statCardWidth,
          child: AppStatCard(
            label: 'Tugas aktif',
            value: '5',
            caption: '2 jatuh tempo hari ini',
          ),
        ),
      );
      await _expectGolden('app_stat_card');
    });

    testWidgets('Progress Bar 0–100 (node 23:88)', (tester) async {
      await pumpGolden(
        tester,
        size: const Size(420, 266),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s20),
          child: SizedBox(
            width: _cardWidth,
            child: Column(
              spacing: AppSpace.s16,
              children: [
                for (var value = 0; value <= 100; value += 10)
                  AppProgressBar(value: value.toDouble()),
              ],
            ),
          ),
        ),
      );
      await _expectGolden('app_progress_bar');
    });

    testWidgets('Nav Item Default dan Active (node 7:43)', (tester) async {
      await pumpGolden(
        tester,
        size: const Size(216, 106),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s20),
          child: Row(
            spacing: AppSpace.s16,
            children: [
              for (final active in [false, true])
                SizedBox(
                  width: _navItemWidth,
                  child: AppNavItem(
                    icon: AppIcons.home,
                    label: 'Beranda',
                    active: active,
                    onTap: () {},
                  ),
                ),
            ],
          ),
        ),
      );
      await _expectGolden('app_nav_item');
    });

    testWidgets('Bottom Nav (node 7:46)', (tester) async {
      await pumpGolden(
        tester,
        size: const Size(_phoneWidth, 79),
        child: SizedBox(
          width: _phoneWidth,
          child: AppBottomNav(currentIndex: 0, onTap: (_) {}),
        ),
      );
      await _expectGolden('app_bottom_nav');
    });

    testWidgets('Top App Bar (node 7:89)', (tester) async {
      await pumpGolden(
        tester,
        size: const Size(_phoneWidth, 56),
        child: SizedBox(
          width: _phoneWidth,
          child: AppTopAppBar(
            title: 'Judul layar',
            leadingIcon: AppIcons.arrowLeft,
            onLeadingPressed: () {},
            trailingIcon: AppIcons.search,
            onTrailingPressed: () {},
          ),
        ),
      );
      await _expectGolden('app_top_app_bar');
    });

    testWidgets('Section Header (node 8:53)', (tester) async {
      await pumpGolden(
        tester,
        size: const Size(_sectionHeaderWidth, 24),
        child: SizedBox(
          width: _sectionHeaderWidth,
          child: AppSectionHeader(
            title: 'Tugas hari ini',
            actionLabel: 'Lihat semua →',
            onActionPressed: () {},
          ),
        ),
      );
      await _expectGolden('app_section_header');
    });
  });

  group('ukuran sama dengan Figma', () {
    testWidgets('Card 136, Stat Card 110, Nav Item 66, Bottom Nav 79, '
        'Top App Bar 56, Section Header 24', (tester) async {
      Future<double> heightOf(Widget child, Type type) async {
        await tester.pumpWidget(
          wrapForTest(SizedBox(width: _phoneWidth, child: child)),
        );
        return tester.getSize(find.byType(type)).height;
      }

      expect(
        await heightOf(
          const AppCard(eyebrow: 'Label', title: 'Judul', body: 'Satu\nDua'),
          AppCard,
        ),
        136,
      );
      expect(
        await heightOf(
          const AppStatCard(label: 'Label', value: '5', caption: 'Teks'),
          AppStatCard,
        ),
        110,
      );
      expect(
        await heightOf(
          AppNavItem(
            icon: AppIcons.home,
            label: 'Beranda',
            active: true,
            onTap: () {},
          ),
          AppNavItem,
        ),
        66,
      );
      expect(
        await heightOf(
          AppBottomNav(currentIndex: 0, onTap: (_) {}),
          AppBottomNav,
        ),
        79,
      );
      expect(
        await heightOf(const AppTopAppBar(title: 'Judul'), AppTopAppBar),
        56,
      );
      expect(
        await heightOf(
          const AppSectionHeader(title: 'Judul', actionLabel: 'Lihat'),
          AppSectionHeader,
        ),
        24,
      );
    });

    testWidgets('Bottom Nav menambah tinggi gesture bar sistem', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(viewPadding: EdgeInsets.only(bottom: 20)),
          child: wrapForTest(
            SizedBox(
              width: _phoneWidth,
              child: AppBottomNav(currentIndex: 0, onTap: (_) {}),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(AppBottomNav)).height, 79 + 20);
    });
  });

  group('perilaku', () {
    testWidgets('tab Bottom Nav mengirim indeks yang diketuk', (tester) async {
      int? tapped;
      await tester.pumpWidget(
        wrapForTest(
          SizedBox(
            width: _phoneWidth,
            child: AppBottomNav(currentIndex: 0, onTap: (i) => tapped = i),
          ),
        ),
      );

      expect(find.text('KEUANGAN'), findsOneWidget);
      await tester.tap(find.text('KEUANGAN'));
      expect(tapped, 3);
    });

    testWidgets('Nav Item aktif berwarna oranye', (tester) async {
      await tester.pumpWidget(
        wrapForTest(
          AppNavItem(
            icon: AppIcons.task,
            label: 'Tugas',
            active: true,
            onTap: () {},
          ),
        ),
      );
      final label = tester.widget<Text>(find.text('TUGAS'));
      expect(label.style?.color, AppColors.accentText);
    });

    testWidgets('ikon Top App Bar bisa diketuk di area 56×56', (tester) async {
      var back = 0;
      var search = 0;
      await tester.pumpWidget(
        wrapForTest(
          SizedBox(
            width: _phoneWidth,
            child: AppTopAppBar(
              title: 'Judul',
              leadingIcon: AppIcons.arrowLeft,
              onLeadingPressed: () => back++,
              trailingIcon: AppIcons.search,
              onTrailingPressed: () => search++,
            ),
          ),
        ),
      );

      // Ketuk di pojok kiri bar (di padding, bukan di ikon).
      final bar = tester.getRect(find.byType(AppTopAppBar));
      await tester.tapAt(bar.topLeft + const Offset(4, 4));
      await tester.tapAt(bar.topRight + const Offset(-4, 4));
      expect(back, 1);
      expect(search, 1);
    });

    testWidgets('Top App Bar tanpa ikon tetap rata kiri 16', (tester) async {
      await tester.pumpWidget(
        wrapForTest(
          const SizedBox(
            width: _phoneWidth,
            child: AppTopAppBar(title: 'Judul'),
          ),
        ),
      );
      final bar = tester.getRect(find.byType(AppTopAppBar));
      final title = tester.getRect(find.text('Judul'));
      expect(title.left - bar.left, AppSpace.s16);
    });

    testWidgets('tautan Section Header bisa diketuk', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrapForTest(
          SizedBox(
            width: _sectionHeaderWidth,
            child: AppSectionHeader(
              title: 'Tugas hari ini',
              actionLabel: 'Lihat semua →',
              onActionPressed: () => taps++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('LIHAT SEMUA →'));
      expect(taps, 1);
    });

    testWidgets('Progress Bar mengisi sesuai persen', (tester) async {
      Future<double> fillWidth(double value) async {
        await tester.pumpWidget(
          wrapForTest(
            SizedBox(width: 200, child: AppProgressBar(value: value)),
          ),
        );
        return tester
            .getSize(
              find.descendant(
                of: find.byType(AppProgressBar),
                matching: find.byType(FractionallySizedBox),
              ),
            )
            .width;
      }

      expect(await fillWidth(0), 0);
      expect(await fillWidth(60), 120);
      expect(await fillWidth(100), 200);
      expect(await fillWidth(150), 200);
    });
  });
}
