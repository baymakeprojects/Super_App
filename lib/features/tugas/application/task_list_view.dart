import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/db/enums.dart';
import 'package:super_app/core/ui/app_badge.dart';
import 'package:super_app/core/utils/date_format.dart';
import 'package:super_app/features/tugas/data/task_repository.dart';

/// Chip filter di layar 03.
enum TaskFilter {
  semua('Semua'),
  hariIni('Hari ini'),
  mingguIni('Minggu ini'),
  selesai('Selesai');

  const TaskFilter(this.label);

  /// Teks chip, disalin dari Figma.
  final String label;
}

/// Kelompok tugas di layar 03, urutannya sama dengan Figma.
/// "Nanti" tidak ada di Figma; ditambahkan atas keputusan Bayu (F-23).
enum TaskGroupKind { hariIni, besok, mingguIni, nanti, selesai }

/// Satu baris tugas siap tampil.
class TaskRowView {
  const TaskRowView({
    required this.id,
    required this.title,
    required this.meta,
    required this.done,
    this.badgeLabel,
    this.badgeType = AppBadgeType.neutral,
  });

  final String id;
  final String title;

  /// "Mata kuliah · jam".
  final String meta;

  final bool done;

  /// `null` = tanpa badge.
  final String? badgeLabel;
  final AppBadgeType badgeType;
}

class TaskGroupView {
  const TaskGroupView({
    required this.kind,
    required this.label,
    required this.rows,
  });

  final TaskGroupKind kind;

  /// Label kecil di atas kelompok, misalnya "Hari ini · Jumat 6 Nov".
  final String label;

  final List<TaskRowView> rows;
}

/// Isi layar 03 untuk satu filter.
class TaskListView {
  const TaskListView({
    required this.headerLabel,
    required this.groups,
    required this.hasAnyTask,
  });

  /// "5 aktif · 2 hari ini", atau "Belum ada tugas".
  final String headerLabel;

  /// Kelompok yang tidak kosong, sesuai filter.
  final List<TaskGroupView> groups;

  /// `false` = belum ada tugas sama sekali → keadaan kosong E2.
  final bool hasAnyTask;
}

/// Aturan layar 03 (design-notes §6, frame 03 dan E4, keputusan Bayu W2-03):
///
/// - **Hari ini**: deadline hari ini **dan** yang sudah lewat (Terlambat).
/// - **Besok**: deadline besok.
/// - **Minggu ini**: 2–7 hari lagi.
/// - **Nanti**: lebih dari 7 hari lagi, atau tanpa deadline.
/// - **Selesai**: tugas selesai; di filter Semua hanya yang selesai dalam
///   7 hari terakhir.
TaskListView buildTaskListView(
  List<TaskListItem> items,
  TaskFilter filter,
  DateTime now,
) {
  final groups = <TaskGroupKind, List<TaskRowView>>{
    for (final kind in TaskGroupKind.values) kind: [],
  };

  final done = [
    for (final item in items)
      if (item.task.status == TaskStatus.done) item,
  ]..sort((a, b) => _completedAt(b.task).compareTo(_completedAt(a.task)));

  for (final item in items) {
    if (item.task.status == TaskStatus.done) continue;
    final kind = _groupOf(item.task, now);
    groups[kind]!.add(_activeRow(item, kind, now));
  }

  final recentLimit = now.subtract(const Duration(days: _recentDoneDays));
  for (final item in done) {
    final recent = !_completedAt(item.task).isBefore(recentLimit);
    if (filter == TaskFilter.selesai || recent) {
      groups[TaskGroupKind.selesai]!.add(_doneRow(item));
    }
  }

  final activeCount = items.length - done.length;
  final todayCount = groups[TaskGroupKind.hariIni]!.length;

  final visible = switch (filter) {
    TaskFilter.semua => TaskGroupKind.values,
    TaskFilter.hariIni => const [TaskGroupKind.hariIni],
    TaskFilter.mingguIni => const [
      TaskGroupKind.hariIni,
      TaskGroupKind.besok,
      TaskGroupKind.mingguIni,
    ],
    TaskFilter.selesai => const [TaskGroupKind.selesai],
  };

  return TaskListView(
    headerLabel: items.isEmpty
        ? 'Belum ada tugas'
        : '$activeCount aktif · $todayCount hari ini',
    hasAnyTask: items.isNotEmpty,
    groups: [
      for (final kind in visible)
        if (groups[kind]!.isNotEmpty)
          TaskGroupView(
            kind: kind,
            label: _groupLabel(kind, now),
            rows: groups[kind]!,
          ),
    ],
  );
}

/// Batas "Minggu ini" (hari ke depan) dan tugas selesai yang masih tampil.
const int _weekDays = 7;
const int _recentDoneDays = 7;

/// Badge status satu tugas, sama di layar 03 dan 16 Detail tugas:
/// Selesai, Terlambat, Hari ini, Besok, "n hari", atau tanggal ("20 Nov").
/// `null` = tugas aktif tanpa deadline.
typedef TaskBadge = ({String label, AppBadgeType type});

TaskBadge? taskStatusBadge(Task task, DateTime now) {
  if (task.status == TaskStatus.done) {
    return (label: 'Selesai', type: AppBadgeType.success);
  }
  final due = task.dueAt?.toLocal();
  if (due == null) return null;
  if (due.isBefore(now)) {
    return (label: 'Terlambat', type: AppBadgeType.danger);
  }
  return switch (_groupOf(task, now)) {
    TaskGroupKind.hariIni => (label: 'Hari ini', type: AppBadgeType.warning),
    TaskGroupKind.besok => (label: 'Besok', type: AppBadgeType.neutral),
    TaskGroupKind.mingguIni => (
      label: '${AppDateFormat.daysBetween(now, due)} hari',
      type: AppBadgeType.neutral,
    ),
    TaskGroupKind.nanti || TaskGroupKind.selesai => (
      label: AppDateFormat.dayMonthShort(due),
      type: AppBadgeType.neutral,
    ),
  };
}

TaskGroupKind _groupOf(Task task, DateTime now) {
  final due = task.dueAt;
  if (due == null) return TaskGroupKind.nanti;
  final days = AppDateFormat.daysBetween(now, due);
  if (days <= 0) return TaskGroupKind.hariIni;
  if (days == 1) return TaskGroupKind.besok;
  if (days <= _weekDays) return TaskGroupKind.mingguIni;
  return TaskGroupKind.nanti;
}

String _groupLabel(TaskGroupKind kind, DateTime now) => switch (kind) {
  TaskGroupKind.hariIni => 'Hari ini · ${AppDateFormat.weekdayDayMonth(now)}',
  TaskGroupKind.besok => 'Besok',
  TaskGroupKind.mingguIni => 'Minggu ini',
  TaskGroupKind.nanti => 'Nanti',
  TaskGroupKind.selesai => 'Selesai',
};

TaskRowView _activeRow(TaskListItem item, TaskGroupKind kind, DateTime now) {
  final task = item.task;
  final due = task.dueAt?.toLocal();

  String? when;
  if (due != null) {
    final days = AppDateFormat.daysBetween(now, due);
    if (due.isBefore(now) && days < 0) {
      when = days == -1 ? 'kemarin' : '${-days} hari lalu';
    } else if (kind == TaskGroupKind.mingguIni) {
      when = '${AppDateFormat.weekdayShort(due)} ${AppDateFormat.time(due)}';
    } else {
      when = AppDateFormat.time(due);
    }
  }
  final badge = taskStatusBadge(task, now);

  return TaskRowView(
    id: task.id,
    title: task.title,
    meta: _meta(item.courseName, when),
    done: false,
    badgeLabel: badge?.label,
    badgeType: badge?.type ?? AppBadgeType.neutral,
  );
}

TaskRowView _doneRow(TaskListItem item) {
  final due = item.task.dueAt?.toLocal();
  return TaskRowView(
    id: item.task.id,
    title: item.task.title,
    meta: _meta(item.courseName, due == null ? null : AppDateFormat.time(due)),
    done: true,
    badgeLabel: 'Selesai',
    badgeType: AppBadgeType.success,
  );
}

String _meta(String? course, String? when) => [?course, ?when].join(' · ');

DateTime _completedAt(Task task) => task.completedAt ?? task.updatedAt;

/// Tugas yang judulnya memuat [query] (huruf besar/kecil sama) untuk H04
/// Pencarian. Urutan: tugas aktif seperti layar 03, lalu semua tugas
/// selesai. Kueri kosong = tanpa hasil.
List<TaskRowView> searchTaskRows(
  List<TaskListItem> items,
  String query,
  DateTime now,
) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return const [];
  final matches = [
    for (final item in items)
      if (item.task.title.toLowerCase().contains(needle)) item,
  ];
  return [
    for (final group in buildTaskListView(
      matches,
      TaskFilter.semua,
      now,
    ).groups)
      if (group.kind != TaskGroupKind.selesai) ...group.rows,
    for (final group in buildTaskListView(
      matches,
      TaskFilter.selesai,
      now,
    ).groups)
      ...group.rows,
  ];
}
