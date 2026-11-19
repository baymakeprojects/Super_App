import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/app.dart';
import 'package:super_app/app/router.dart';
import 'package:super_app/app/routes.dart';
import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/db/database_provider.dart';
import 'package:super_app/core/db/enums.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/features/auth/application/current_user_id_provider.dart';
import 'package:super_app/features/keuangan/application/keuangan_providers.dart';
import 'package:super_app/features/keuangan/data/finance_repository.dart';

import '../../../helpers/svg.dart';
import '../../../helpers/test_database.dart';

/// "Sekarang" seperti status bar frame 05: Jumat 6 Nov 2026 08.15.
final _now = DateTime(2026, 11, 6, 8, 15);

const Size _phone = Size(412, 917);
const double _statusBar = 32;

Future<GoRouter> _pump(
  WidgetTester tester, {
  Future<void> Function(FinanceRepository repo)? seed,
}) async {
  tester.view
    ..physicalSize = _phone
    ..devicePixelRatio = 1
    ..padding = const FakeViewPadding(top: _statusBar)
    ..viewPadding = const FakeViewPadding(top: _statusBar);
  addTearDown(tester.view.reset);

  final database = testDatabase();
  addTearDown(database.close);
  await seed?.call(
    FinanceRepository(database, userId: devLocalUserId, now: () => _now),
  );

  final router = buildAppRouter(initialLocation: AppRoutes.keuangan);
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      appRouterProvider.overrideWithValue(router),
      appDatabaseProvider.overrideWithValue(database),
      clockProvider.overrideWithValue(() => _now),
    ],
  );
  addTearDown(container.dispose);

  await precacheAppIcons(tester);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const SuperApp()),
  );
  await tester.pumpAndSettle();
  return router;
}

/// Isi contoh frame 05: saldo Rp1.250.000, masuk 2jt, keluar 750rb.
Future<void> _seedFigma(FinanceRepository repo) async {
  await repo.ensureDefaultCategories();
  final makan = (await repo.getCategories(MoneyKind.expense)).first;
  final tunai = await repo.addWallet(
    name: 'Tunai',
    kind: WalletKind.cash,
    openingBalance: 165000,
  );
  final bank = await repo.addWallet(name: 'Bank', kind: WalletKind.bank);
  await repo.addWallet(
    name: 'E-wallet',
    kind: WalletKind.ewallet,
    openingBalance: 200000,
  );
  TransactionInput tx(
    String wallet,
    MoneyKind kind,
    int amount,
    DateTime at, {
    String? notes,
    String? categoryId,
  }) => (
    walletId: wallet,
    categoryId: categoryId,
    kind: kind,
    amount: amount,
    notes: notes,
    occurredAt: at,
  );
  // Bulan ini: masuk 0,5jt + 1,5jt = 2jt; keluar 735rb + 15rb = 750rb.
  // Tunai: 165rb − 15rb = 150rb. Bank: 2jt − 735rb − 365rb (Oktober)
  // = 900rb. E-wallet: saldo awal 200rb. Total Rp1.250.000.
  await repo.addTransaction(
    tx(bank, MoneyKind.expense, 365000, DateTime(2026, 10, 25)),
  );
  await repo.addTransaction(
    tx(bank, MoneyKind.expense, 735000, DateTime(2026, 11, 1, 6)),
  );
  await repo.addTransaction(
    tx(bank, MoneyKind.income, 500000, DateTime(2026, 11, 1, 7)),
  );
  await repo.addTransaction(
    tx(
      bank,
      MoneyKind.income,
      1500000,
      DateTime(2026, 11, 1, 8),
      notes: 'Uang saku',
    ),
  );
  await repo.addTransaction(
    tx(
      tunai,
      MoneyKind.expense,
      15000,
      DateTime(2026, 11, 6, 7, 10),
      notes: 'Sarapan',
      categoryId: makan.id,
    ),
  );
}

void main() {
  group('golden sama dengan Figma', () {
    testWidgets('05 Keuangan (16:300)', (tester) async {
      await _pump(tester, seed: _seedFigma);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/keuangan_05.png'),
      );
    });

    testWidgets('E3 Keuangan kosong (67:2026)', (tester) async {
      await _pump(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/keuangan_e3_kosong.png'),
      );
    });
  });

  group('perilaku', () {
    testWidgets('saldo, ringkasan bulan, dan transaksi terakhir', (
      tester,
    ) async {
      await _pump(tester, seed: _seedFigma);
      expect(find.text('NOVEMBER 2026'), findsOneWidget);
      expect(find.text('Rp1.250.000'), findsOneWidget);
      expect(find.text('+Rp2jt'), findsOneWidget);
      expect(find.text('−Rp750rb'), findsOneWidget);
      expect(find.text('Rp150.000'), findsOneWidget);
      expect(find.text('Rp900.000'), findsOneWidget);
      expect(find.text('TUNAI · MAKAN · 07.10'), findsOneWidget);
      expect(find.text('BANK · PEMASUKAN · 1 NOV'), findsWidgets);
      expect(find.text('−Rp15.000'), findsOneWidget);
      expect(find.text('+Rp1.500.000'), findsOneWidget);
      // Tahap 2 disembunyikan.
      expect(find.text('Tagihan terdekat'), findsNothing);
      expect(find.text('RINGKASAN'), findsNothing);
    });

    testWidgets('FAB dan ketuk transaksi membuka rute yang benar', (
      tester,
    ) async {
      final router = await _pump(tester, seed: _seedFigma);
      await tester.tap(find.bySemanticsLabel('Transaksi baru'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, AppRoutes.keuanganTransaksiBaru);
      router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sarapan'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, startsWith('/keuangan/transaksi/'));
    });

    testWidgets('E3: tanpa FAB, tombol membuka setup dompet', (tester) async {
      final router = await _pump(tester);
      expect(find.text('Belum ada dompet'), findsOneWidget);
      expect(find.byType(AppFab), findsNothing);
      await tester.tap(find.text('+ BUAT DOMPET'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, AppRoutes.setupDompet);
    });

    testWidgets('lebih dari 3 dompet: baris digeser', (tester) async {
      await _pump(
        tester,
        seed: (repo) async {
          for (final name in ['A', 'B', 'C', 'D']) {
            await repo.addWallet(name: name, kind: WalletKind.cash);
          }
        },
      );
      expect(find.byType(AppWalletCard), findsNWidgets(4));
      expect(
        find.ancestor(
          of: find.byType(AppWalletCard).first,
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
    });
  });

  test('baris transaksi tanpa catatan dan kategori', () {
    final now = DateTime(2026, 11, 6, 9);
    final row = transactionRowOf(
      TransactionListItem(
        transaction: MoneyTransaction(
          id: 't',
          userId: 'u',
          walletId: 'w',
          kind: MoneyKind.expense,
          amount: 20000,
          occurredAt: DateTime(2026, 11, 5, 12),
          createdAt: now,
          updatedAt: now,
        ),
        walletName: 'Tunai',
        categoryName: null,
      ),
      now,
    );
    expect(
      (row.title, row.meta, row.amount),
      ('Pengeluaran', 'Tunai · Pengeluaran · 5 Nov', '−Rp20.000'),
    );
  });
}
