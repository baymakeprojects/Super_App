import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/features/tugas/data/task_repository_provider.dart';

/// Snackbar Urungkan di layar 03 (E4). Diatur di sini, bukan lewat
/// ScaffoldMessenger, supaya posisinya persis E4 (FAB di atas snackbar) dan
/// supaya layar lain (16 Detail tugas) bisa memicunya setelah kembali ke
/// daftar.
class TaskSnack {
  const TaskSnack({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.onUndo,
  });

  final String message;
  final AppIcons icon;
  final Color iconColor;
  final Future<void> Function() onUndo;
}

final taskSnackbarProvider = NotifierProvider<TaskSnackbarNotifier, TaskSnack?>(
  TaskSnackbarNotifier.new,
);

class TaskSnackbarNotifier extends Notifier<TaskSnack?> {
  Timer? _timer;

  @override
  TaskSnack? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  /// Tampilkan snackbar selama 4 detik; snackbar sebelumnya diganti.
  void show(TaskSnack snack) {
    _timer?.cancel();
    state = snack;
    _timer = Timer(appSnackbarDuration, hide);
  }

  void hide() {
    _timer?.cancel();
    _timer = null;
    state = null;
  }

  /// Aksi "Urungkan": tutup snackbar lalu kembalikan perubahan.
  Future<void> undo() async {
    final snack = state;
    hide();
    await snack?.onUndo();
  }

  /// Tandai selesai + snackbar Urungkan (keputusan Bayu, W2-03: teks
  /// Tugas "…" selesai, ikon centang hijau).
  Future<void> markDone(String id, String title) async {
    final repository = ref.read(taskRepositoryProvider);
    await repository.setDone(id, done: true);
    show(
      TaskSnack(
        message: 'Tugas “$title” selesai',
        icon: AppIcons.check,
        iconColor: AppColors.success,
        onUndo: () => repository.setDone(id, done: false),
      ),
    );
  }

  /// Hapus + snackbar Urungkan, teks dari frame E4.
  /// Dipakai layar 16 Detail tugas setelah kembali ke daftar.
  Future<void> delete(String id, String title) async {
    final repository = ref.read(taskRepositoryProvider);
    await repository.deleteTask(id);
    show(
      TaskSnack(
        message: 'Tugas “$title” dihapus',
        icon: AppIcons.trash,
        iconColor: AppColors.lightGray,
        onUndo: () => repository.restoreTask(id),
      ),
    );
  }
}
