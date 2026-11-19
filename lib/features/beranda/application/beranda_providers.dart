import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/features/beranda/application/beranda_view.dart';
import 'package:super_app/features/keuangan/data/finance_repository.dart';
import 'package:super_app/features/keuangan/data/finance_repository_provider.dart';
import 'package:super_app/features/kuliah/application/kuliah_providers.dart';

/// Kelas berikutnya hari ini. `null` = kartu disembunyikan.
final nextClassProvider = Provider<NextClass?>((ref) {
  final entries = ref.watch(scheduleProvider).value ?? const [];
  return nextClassOf(entries, ref.watch(clockProvider)());
});

/// Masuk dan keluar minggu ini (Senin sampai sekarang), untuk keterangan
/// Stat Card Saldo.
final weekSummaryProvider = StreamProvider<MonthSummary>((ref) {
  final now = ref.watch(clockProvider)();
  final start = weekStartOf(now);
  return ref
      .watch(financeRepositoryProvider)
      .watchSummaryBetween(start, start.add(const Duration(days: 7)));
});
