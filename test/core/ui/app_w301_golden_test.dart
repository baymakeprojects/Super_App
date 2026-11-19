import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';

import '../../helpers/golden.dart';

// Ukuran instance di frame peraga Figma.
const double _itemWidth = 372;

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
  testWidgets('Transaction Item Expense dan Income (node 8:94)', (
    tester,
  ) async {
    Widget item(AppTransactionType type) => SizedBox(
      width: _itemWidth,
      child: AppTransactionItem(
        title: 'Transaksi',
        meta: 'Dompet · Kategori · 12.30',
        amount: 'Rp50.000',
        type: type,
      ),
    );

    await _golden(
      tester,
      'app_transaction_item',
      const Size(800, 105),
      _frame(
        Row(
          spacing: AppSpace.s16,
          children: [
            item(AppTransactionType.expense),
            item(AppTransactionType.income),
          ],
        ),
      ),
    );
  });

  testWidgets('Wallet Card (node 9:82)', (tester) async {
    await _golden(
      tester,
      'app_wallet_card',
      const Size(140, 78),
      const AppWalletCard(label: 'Tunai', amount: 'Rp150.000'),
    );
  });

  testWidgets('Banner Warning, Danger, Info, Success (node 65:226)', (
    tester,
  ) async {
    await _golden(
      tester,
      'app_banner',
      const Size(412, 352),
      _frame(
        SizedBox(
          width: _itemWidth,
          child: Column(
            spacing: AppSpace.s16,
            children: [
              for (final type in AppBannerType.values)
                AppBanner(
                  type: type,
                  title: 'Kamu sedang offline',
                  body: '3 perubahan akan disinkron saat online',
                  actionLabel: 'Coba lagi',
                  onAction: () {},
                ),
            ],
          ),
        ),
      ),
    );
  });

  testWidgets('Banner tanpa keterangan dan aksi', (tester) async {
    await pumpGolden(
      tester,
      size: const Size(412, 100),
      child: const SizedBox(
        width: _itemWidth,
        child: AppBanner(type: AppBannerType.danger, title: 'Gagal menyimpan'),
      ),
    );
    expect(find.text('Gagal menyimpan'), findsOneWidget);
    expect(find.byType(GestureDetector), findsNothing);
  });

  testWidgets('aksi Banner dan ketuk Transaction Item terpanggil', (
    tester,
  ) async {
    var action = 0;
    var tapped = 0;
    await tester.pumpWidget(
      wrapForTest(
        SizedBox(
          width: _itemWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBanner(
                type: AppBannerType.warning,
                title: 'Offline',
                actionLabel: 'Coba lagi',
                onAction: () => action++,
              ),
              AppTransactionItem(
                title: 'Makan',
                meta: 'Tunai',
                amount: 'Rp10.000',
                type: AppTransactionType.expense,
                onTap: () => tapped++,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('COBA LAGI'));
    await tester.tap(find.text('Makan'));
    expect((action, tapped), (1, 1));
  });
}
