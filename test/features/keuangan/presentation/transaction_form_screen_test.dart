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
import 'package:super_app/features/keuangan/data/finance_repository.dart';
import 'package:super_app/features/keuangan/data/finance_repository_provider.dart';
import 'package:super_app/features/keuangan/presentation/transaction_form_screen.dart';

import '../../../helpers/svg.dart';
import '../../../helpers/test_database.dart';

/// "Sekarang" seperti frame 17: Jumat 6 Nov 2026 07.10.
final _now = DateTime(2026, 11, 6, 7, 10);

const Size _phone = Size(412, 917);
const double _statusBar = 32;

class _App {
  _App(this.router, this.database);

  final GoRouter router;
  final AppDatabase database;

  Future<List<MoneyTransaction>> transactions() =>
      database.select(database.transactions).get();
}

/// Server pura-pura tidak merespons untuk [failures] simpanan pertama.
class _FlakyFinance extends FinanceRepository {
  _FlakyFinance(super.database, {required super.userId});

  int failures = 1;

  @override
  Future<String> addTransaction(TransactionInput input) {
    if (failures > 0) {
      failures--;
      throw Exception('server tidak merespons');
    }
    return super.addTransaction(input);
  }
}

Future<_App> _pump(
  WidgetTester tester, {
  bool wallets = true,
  bool flaky = false,
}) async {
  tester.view
    ..physicalSize = _phone
    ..devicePixelRatio = 1
    ..padding = const FakeViewPadding(top: _statusBar)
    ..viewPadding = const FakeViewPadding(top: _statusBar);
  addTearDown(tester.view.reset);

  final database = testDatabase();
  addTearDown(database.close);
  if (wallets) {
    final repo = FinanceRepository(database, userId: devLocalUserId);
    for (final (name, kind, balance) in [
      ('Tunai', WalletKind.cash, 150000),
      ('Bank', WalletKind.bank, 900000),
      ('E-wallet', WalletKind.ewallet, 200000),
    ]) {
      await repo.addWallet(name: name, kind: kind, openingBalance: balance);
    }
  }

  // Dibuka dari 05 seperti di app.
  final router = buildAppRouter(
    initialLocation: AppRoutes.keuanganTransaksiBaru,
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      appRouterProvider.overrideWithValue(router),
      appDatabaseProvider.overrideWithValue(database),
      clockProvider.overrideWithValue(() => _now),
      if (flaky)
        financeRepositoryProvider.overrideWithValue(
          _FlakyFinance(database, userId: devLocalUserId),
        ),
    ],
  );
  addTearDown(container.dispose);

  await precacheAppIcons(tester);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const SuperApp()),
  );
  await tester.pumpAndSettle();
  return _App(router, database);
}

/// Kolom Nominal: TextField pertama.
Finder get _amount => find.byType(TextField).first;

Finder _input(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(AppInput)),
  matching: find.byType(TextField),
);

Finder _select(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(AppSelect));

/// Isi contoh frame 17. Nominal diketik terakhir supaya garisnya oranye.
Future<void> _fillFigma(WidgetTester tester) async {
  await tester.enterText(_input('CATATAN'), 'Sarapan nasi uduk di kantin');
  await tester.enterText(_amount, '15000');
  await tester.pumpAndSettle();
}

void main() {
  group('golden sama dengan Figma', () {
    testWidgets('17 Transaksi baru (31:1482)', (tester) async {
      await _pump(tester);
      await _fillFigma(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/keuangan_17_transaksi_baru.png'),
      );
    });

    testWidgets('P06 Pilih dompet (51:617)', (tester) async {
      await _pump(tester);
      await _fillFigma(tester);
      await tester.tap(_select('DOMPET'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/keuangan_p06_dompet.png'),
      );
    });

    testWidgets('P07 Dompet baru (51:691)', (tester) async {
      await _pump(tester);
      await _fillFigma(tester);
      await tester.tap(_select('DOMPET'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ TAMBAH DOMPET'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('BANK').last);
      await tester.enterText(_input('SALDO AWAL'), '500000');
      await tester.enterText(_input('NAMA DOMPET'), 'Tabungan kos');
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/keuangan_p07_dompet_baru.png'),
      );
    });
  });

  testWidgets('golden: G3 Gagal menyimpan (137:4395)', (tester) async {
    await _pump(tester, flaky: true);
    await _fillFigma(tester);
    await tester.tap(find.text('SIMPAN TRANSAKSI'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/keuangan_g3_gagal_menyimpan.png'),
    );
  });

  testWidgets('G3: isian tetap, Ulangi menyimpan lalu kembali ke 05', (
    tester,
  ) async {
    final app = await _pump(tester, flaky: true);
    await _fillFigma(tester);
    await tester.tap(find.text('SIMPAN TRANSAKSI'));
    await tester.pumpAndSettle();

    expect(find.text(saveFailedMessage), findsOneWidget);
    expect(app.router.state.matchedLocation, AppRoutes.keuanganTransaksiBaru);
    expect(find.text('Rp15.000'), findsOneWidget);
    expect(await app.transactions(), isEmpty);

    await tester.tap(find.text('ULANGI'));
    await tester.pumpAndSettle();
    expect(app.router.state.matchedLocation, AppRoutes.keuangan);
    expect((await app.transactions()).single.amount, 15000);
  });

  group('perilaku', () {
    testWidgets('simpan pengeluaran: kembali ke 05, saldo berkurang', (
      tester,
    ) async {
      final app = await _pump(tester);
      expect(find.text('Hari ini'), findsOneWidget);
      expect(find.text('07.10'), findsOneWidget);
      await _fillFigma(tester);
      expect(find.text('Rp15.000'), findsOneWidget);

      await tester.tap(find.text('SIMPAN TRANSAKSI'));
      await tester.pumpAndSettle();

      expect(app.router.state.matchedLocation, AppRoutes.keuangan);
      expect(find.text('Rp135.000'), findsOneWidget); // Tunai 150rb − 15rb
      final t = (await app.transactions()).single;
      expect(
        (t.kind, t.amount, t.notes, t.occurredAt),
        (
          MoneyKind.expense,
          15000,
          'Sarapan nasi uduk di kantin',
          DateTime(2026, 11, 6, 7, 10),
        ),
      );
      final makan = await (app.database.select(
        app.database.categories,
      )..where((c) => c.id.equals(t.categoryId!))).getSingle();
      expect(makan.name, 'Makan');
    });

    testWidgets('nominal 0: pesan di kolomnya, tidak tersimpan', (
      tester,
    ) async {
      final app = await _pump(tester);
      await tester.tap(find.text('SIMPAN TRANSAKSI'));
      await tester.pumpAndSettle();
      expect(find.text('Nominal wajib diisi'), findsOneWidget);
      expect(await app.transactions(), isEmpty);

      await tester.enterText(_amount, '5');
      await tester.pumpAndSettle();
      expect(find.text('Nominal wajib diisi'), findsNothing);
    });

    testWidgets('pemasukan: chip kategori pemasukan, dompet Bank', (
      tester,
    ) async {
      final app = await _pump(tester);
      await tester.tap(find.text('PEMASUKAN'));
      await tester.pumpAndSettle();
      expect(find.text('UANG SAKU'), findsOneWidget);
      expect(find.text('MAKAN'), findsNothing);
      await tester.tap(find.text('GAJI'));
      await tester.enterText(_amount, '1500000');

      await tester.tap(_select('DOMPET'));
      await tester.pumpAndSettle();
      expect(find.text('Total saldo Rp1.250.000'), findsOneWidget);
      await tester.tap(find.text('Bank'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SIMPAN TRANSAKSI'));
      await tester.pumpAndSettle();
      final t = (await app.transactions()).single;
      expect((t.kind, t.amount), (MoneyKind.income, 1500000));
      final wallet = await (app.database.select(
        app.database.wallets,
      )..where((w) => w.id.equals(t.walletId))).getSingle();
      expect(wallet.name, 'Bank');
    });

    testWidgets('P06 → P07: dompet baru langsung terpilih', (tester) async {
      final app = await _pump(tester);
      await tester.tap(_select('DOMPET'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ TAMBAH DOMPET'));
      await tester.pumpAndSettle();
      expect(find.text('Pilih dompet'), findsNothing); // sheet diganti

      await tester.tap(find.text('SIMPAN DOMPET'));
      await tester.pumpAndSettle();
      expect(find.text('Nama dompet wajib diisi'), findsOneWidget);

      await tester.enterText(_input('NAMA DOMPET'), 'Tabungan kos');
      await tester.tap(find.text('SIMPAN DOMPET'));
      await tester.pumpAndSettle();
      expect(find.text('Tabungan kos'), findsOneWidget);

      await tester.enterText(_amount, '10000');
      await tester.tap(find.text('SIMPAN TRANSAKSI'));
      await tester.pumpAndSettle();
      final t = (await app.transactions()).single;
      final wallet = await (app.database.select(
        app.database.wallets,
      )..where((w) => w.id.equals(t.walletId))).getSingle();
      expect(wallet.name, 'Tabungan kos');
    });

    testWidgets('tanggal lewat P01 tanpa pilihan Tanpa tanggal', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(_select('TANGGAL'));
      await tester.pumpAndSettle();
      expect(find.text('TANPA TANGGAL'), findsNothing);
      await tester.tap(find.text('BESOK'));
      await tester.pump();
      await tester.tap(find.text('PILIH'));
      await tester.pumpAndSettle();
      expect(find.text('Sab, 7 Nov'), findsOneWidget);
    });
  });
}
