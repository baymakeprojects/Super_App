import 'dart:async';

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

import '../../../helpers/svg.dart';
import '../../../helpers/test_database.dart';

/// "Sekarang" seperti frame H11: Jumat 6 Nov 2026 07.11.
final _now = DateTime(2026, 11, 6, 7, 11);

const Size _phone = Size(412, 917);
const double _statusBar = 32;

class _App {
  _App(this.router, this.database, this.transactionId);

  final GoRouter router;
  final AppDatabase database;
  final String transactionId;

  Future<MoneyTransaction> transaction() => (database.select(
    database.transactions,
  )..where((t) => t.id.equals(transactionId))).getSingle();
}

/// Contoh frame H11: Sarapan −Rp15.000, Tunai, Makan, hari ini 07.10.
/// Dibuka dari 05 seperti di app.
Future<_App> _pump(WidgetTester tester) async {
  tester.view
    ..physicalSize = _phone
    ..devicePixelRatio = 1
    ..padding = const FakeViewPadding(top: _statusBar)
    ..viewPadding = const FakeViewPadding(top: _statusBar);
  addTearDown(tester.view.reset);

  final database = testDatabase();
  addTearDown(database.close);
  final repo = FinanceRepository(database, userId: devLocalUserId);
  await repo.ensureDefaultCategories();
  final makan = (await repo.getCategories(MoneyKind.expense)).first;
  final tunai = await repo.addWallet(
    name: 'Tunai',
    kind: WalletKind.cash,
    openingBalance: 165000,
  );
  await repo.addWallet(name: 'Bank', kind: WalletKind.bank);
  final id = await repo.addTransaction((
    walletId: tunai,
    categoryId: makan.id,
    kind: MoneyKind.expense,
    amount: 15000,
    notes: 'Sarapan nasi uduk di kantin',
    occurredAt: DateTime(2026, 11, 6, 7, 10),
  ));

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
  unawaited(router.push(AppRoutes.keuanganTransaksi(id)));
  await tester.pumpAndSettle();
  return _App(router, database, id);
}

Future<void> _waitSnackbar(WidgetTester tester) async {
  await tester.pump(appSnackbarDuration);
  await tester.pumpAndSettle();
}

void main() {
  group('golden sama dengan Figma', () {
    testWidgets('H11 Ubah transaksi (185:13492)', (tester) async {
      await _pump(tester);
      // Frame H11 memperlihatkan Nominal dalam keadaan fokus.
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/keuangan_h11_ubah.png'),
      );
    });

    testWidgets('P47 Hapus transaksi (185:13574)', (tester) async {
      await _pump(tester);
      await tester.tap(find.bySemanticsLabel('Hapus transaksi'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/keuangan_p47_hapus.png'),
      );
    });
  });

  group('perilaku', () {
    testWidgets('isian awal dari transaksi, simpan perubahan', (tester) async {
      final app = await _pump(tester);
      expect(find.text('Ubah transaksi'), findsOneWidget);
      expect(find.text('Rp15.000'), findsOneWidget);
      expect(find.text('Tunai'), findsOneWidget);
      expect(find.text('07.10'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '20000');
      await tester.tap(find.text('TRANSPORT'));
      await tester.tap(find.text('SIMPAN PERUBAHAN'));
      await tester.pumpAndSettle();

      expect(app.router.state.matchedLocation, AppRoutes.keuangan);
      final t = await app.transaction();
      expect(t.amount, 20000);
      expect(find.text('Rp145.000'), findsWidgets); // Tunai 165rb − 20rb
    });

    testWidgets('Batal tidak menyimpan', (tester) async {
      final app = await _pump(tester);
      await tester.enterText(find.byType(TextField).first, '99000');
      await tester.tap(find.text('BATAL'));
      await tester.pumpAndSettle();
      expect((await app.transaction()).amount, 15000);
    });

    testWidgets('hapus lewat P47, lalu Urungkan dari 05', (tester) async {
      final app = await _pump(tester);
      await tester.tap(find.bySemanticsLabel('Hapus transaksi'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          '“Sarapan nasi uduk di kantin” (−Rp15.000) akan dihapus, dan '
          'saldo Tunai bertambah lagi Rp15.000. Setelah dihapus, kamu '
          'masih bisa mengurungkannya dari snackbar.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('HAPUS TRANSAKSI'));
      await tester.pumpAndSettle();

      expect(app.router.state.matchedLocation, AppRoutes.keuangan);
      expect(
        find.text('Transaksi “Sarapan nasi uduk di kantin” dihapus'),
        findsOneWidget,
      );
      expect((await app.transaction()).deletedAt, isNotNull);
      expect(find.text('Rp165.000'), findsWidgets);

      await tester.tap(find.text('URUNGKAN'));
      await tester.pumpAndSettle();
      expect((await app.transaction()).deletedAt, isNull);
      expect(find.text('Rp150.000'), findsWidgets);
    });

    testWidgets('P47 Batal tidak menghapus; snackbar hilang sendiri', (
      tester,
    ) async {
      final app = await _pump(tester);
      await tester.tap(find.bySemanticsLabel('Hapus transaksi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('BATAL').last);
      await tester.pumpAndSettle();
      expect((await app.transaction()).deletedAt, isNull);

      await tester.tap(find.bySemanticsLabel('Hapus transaksi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('HAPUS TRANSAKSI'));
      await tester.pumpAndSettle();
      expect(find.byType(AppSnackbar), findsOneWidget);
      await _waitSnackbar(tester);
      expect(find.byType(AppSnackbar), findsNothing);
    });
  });
}
