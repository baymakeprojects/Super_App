import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/features/beranda/application/beranda_view.dart';
import 'package:super_app/features/keuangan/application/keuangan_providers.dart';
import 'package:super_app/features/keuangan/data/finance_repository.dart';
import 'package:super_app/features/keuangan/data/finance_repository_provider.dart';
import 'package:super_app/features/kuliah/application/kuliah_providers.dart';
import 'package:super_app/features/tugas/application/task_list_providers.dart';

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

/// Isi checklist "Siapkan Super App kamu" (E1, Figma 67:1943).
typedef SetupChecklist = ({bool schedule, bool task, bool transaction});

/// Jumlah langkah checklist yang sudah selesai.
int setupChecklistDone(SetupChecklist c) =>
    [c.schedule, c.task, c.transaction].where((done) => done).length;

/// Checklist E1. `null` = data belum siap (kartu belum ditampilkan supaya
/// tidak berkedip). Tercentang otomatis: ada jadwal kuliah di semester
/// aktif, ada tugas (juga yang selesai), ada transaksi.
final setupChecklistProvider = Provider<SetupChecklist?>((ref) {
  final semester = ref.watch(activeSemesterProvider);
  final schedule = ref.watch(scheduleProvider);
  final tasks = ref.watch(taskListItemsProvider);
  final transactions = ref.watch(recentTransactionsProvider);
  if (!semester.hasValue || !tasks.hasValue || !transactions.hasValue) {
    return null;
  }
  // Tanpa semester aktif, jadwal tidak pernah dimuat.
  if (semester.value != null && !schedule.hasValue) return null;
  return (
    schedule: (schedule.value ?? const []).isNotEmpty,
    task: tasks.requireValue.isNotEmpty,
    transaction: transactions.requireValue.isNotEmpty,
  );
});
