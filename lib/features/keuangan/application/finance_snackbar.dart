import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/features/keuangan/data/finance_repository_provider.dart';

/// Snackbar Urungkan di layar 05 (pola E4). Dipicu H11 setelah hapus lalu
/// kembali ke 05, jadi diatur di sini, bukan lewat ScaffoldMessenger.
class FinanceSnack {
  const FinanceSnack({required this.message, required this.onUndo});

  final String message;
  final Future<void> Function() onUndo;
}

final financeSnackbarProvider =
    NotifierProvider<FinanceSnackbarNotifier, FinanceSnack?>(
      FinanceSnackbarNotifier.new,
    );

class FinanceSnackbarNotifier extends Notifier<FinanceSnack?> {
  Timer? _timer;

  @override
  FinanceSnack? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void show(FinanceSnack snack) {
    _timer?.cancel();
    state = snack;
    _timer = Timer(appSnackbarDuration, hide);
  }

  void hide() {
    _timer?.cancel();
    _timer = null;
    state = null;
  }

  Future<void> undo() async {
    final snack = state;
    hide();
    await snack?.onUndo();
  }

  /// Hapus transaksi + snackbar Urungkan (pola E4, keputusan Bayu W3-05:
  /// "Transaksi “…” dihapus").
  Future<void> delete(String id, String title) async {
    final repository = ref.read(financeRepositoryProvider);
    await repository.deleteTransaction(id);
    show(
      FinanceSnack(
        message: 'Transaksi “$title” dihapus',
        onUndo: () => repository.restoreTransaction(id),
      ),
    );
  }
}
