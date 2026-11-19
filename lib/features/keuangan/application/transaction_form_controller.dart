import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/db/enums.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/core/utils/date_format.dart';
import 'package:super_app/features/keuangan/data/finance_repository.dart';
import 'package:super_app/features/keuangan/data/finance_repository_provider.dart';

/// Isian form 17 Transaksi baru dan H11 Ubah transaksi.
class TransactionFormState {
  const TransactionFormState({
    required this.kind,
    required this.amount,
    required this.categoryId,
    required this.walletId,
    required this.date,
    required this.hour,
    required this.minute,
    required this.notes,
    required this.showAmountError,
    required this.saving,
  });

  final MoneyKind kind;

  /// Rupiah; 0 = belum diisi.
  final int amount;

  /// `null` = kategori pertama arah uang ini (chip pertama terpilih).
  final String? categoryId;

  /// `null` = dompet pertama.
  final String? walletId;

  /// Tanggal tanpa jam.
  final DateTime date;
  final int hour;
  final int minute;
  final String notes;

  /// Nominal 0 saat Simpan (pola G2, F-43).
  final bool showAmountError;
  final bool saving;

  DateTime get occurredAt =>
      DateTime(date.year, date.month, date.day, hour, minute);

  TransactionFormState copyWith({
    MoneyKind? kind,
    int? amount,
    (String?,)? categoryId,
    (String?,)? walletId,
    DateTime? date,
    int? hour,
    int? minute,
    String? notes,
    bool? showAmountError,
    bool? saving,
  }) {
    return TransactionFormState(
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      categoryId: categoryId != null ? categoryId.$1 : this.categoryId,
      walletId: walletId != null ? walletId.$1 : this.walletId,
      date: date ?? this.date,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      notes: notes ?? this.notes,
      showAmountError: showAmountError ?? this.showAmountError,
      saving: saving ?? this.saving,
    );
  }
}

/// Isian awal H11, dibaca sekali. `null` = tidak ada atau dihapus.
final transactionEditSourceProvider = FutureProvider.autoDispose
    .family<MoneyTransaction?, String>((ref, id) async {
      final item = await ref.read(financeRepositoryProvider).getTransaction(id);
      return item?.transaction;
    });

/// Kategori bawaan dibuat sekali sebelum form dipakai.
final defaultCategoriesProvider = FutureProvider.autoDispose<void>(
  (ref) => ref.read(financeRepositoryProvider).ensureDefaultCategories(),
);

/// Chip kategori satu arah uang.
final categoriesProvider = StreamProvider.autoDispose
    .family<List<Category>, MoneyKind>(
      (ref, kind) => ref.watch(financeRepositoryProvider).watchCategories(kind),
    );

/// Form transaksi. Argumen `null` = 17 Transaksi baru; id = H11 (pastikan
/// [transactionEditSourceProvider] untuk id itu sudah selesai dibaca).
final transactionFormProvider = NotifierProvider.autoDispose
    .family<TransactionFormController, TransactionFormState, String?>(
      TransactionFormController.new,
    );

class TransactionFormController extends Notifier<TransactionFormState> {
  TransactionFormController(this.transactionId);

  /// `null` = transaksi baru.
  final String? transactionId;

  @override
  TransactionFormState build() {
    final id = transactionId;
    if (id != null) {
      final source = ref.read(transactionEditSourceProvider(id)).value;
      if (source != null) {
        final at = source.occurredAt.toLocal();
        return TransactionFormState(
          kind: source.kind,
          amount: source.amount,
          categoryId: source.categoryId,
          walletId: source.walletId,
          date: AppDateFormat.dateOnly(at),
          hour: at.hour,
          minute: at.minute,
          notes: source.notes ?? '',
          showAmountError: false,
          saving: false,
        );
      }
    }

    // Isian awal (design-notes §6, PRD Keuangan): pengeluaran, tanggal dan
    // jam sekarang, kategori dan dompet pertama.
    final now = ref.read(clockProvider)();
    return TransactionFormState(
      kind: MoneyKind.expense,
      amount: 0,
      categoryId: null,
      walletId: null,
      date: AppDateFormat.dateOnly(now),
      hour: now.hour,
      minute: now.minute,
      notes: '',
      showAmountError: false,
      saving: false,
    );
  }

  /// Ganti arah uang; kategori kembali ke chip pertama arah itu.
  void setKind(MoneyKind kind) {
    if (kind == state.kind) return;
    state = state.copyWith(kind: kind, categoryId: (null,));
  }

  void setAmount(int amount) =>
      state = state.copyWith(amount: amount, showAmountError: false);

  void setCategory(String id) => state = state.copyWith(categoryId: (id,));

  void setWallet(String id) => state = state.copyWith(walletId: (id,));

  void setDate(DateTime date) =>
      state = state.copyWith(date: AppDateFormat.dateOnly(date));

  void setTime(int hour, int minute) =>
      state = state.copyWith(hour: hour, minute: minute);

  void setNotes(String notes) => state = state.copyWith(notes: notes);

  /// Simpan. [categories] dan [wallets] = pilihan yang tampil, untuk
  /// memakai pilihan pertama kalau belum diganti. Mengembalikan id, atau
  /// `null` kalau nominal masih 0 atau belum ada dompet.
  Future<String?> save({
    required List<Category> categories,
    required List<Wallet> wallets,
  }) async {
    if (state.saving) return null;
    if (state.amount <= 0) {
      state = state.copyWith(showAmountError: true);
      return null;
    }
    final walletId =
        state.walletId ?? (wallets.isEmpty ? null : wallets.first.id);
    if (walletId == null) return null;
    final categoryId =
        state.categoryId ?? (categories.isEmpty ? null : categories.first.id);

    state = state.copyWith(saving: true);
    try {
      final notes = state.notes.trim();
      final TransactionInput input = (
        walletId: walletId,
        categoryId: categoryId,
        kind: state.kind,
        amount: state.amount,
        notes: notes.isEmpty ? null : notes,
        occurredAt: state.occurredAt,
      );
      final repository = ref.read(financeRepositoryProvider);
      final id = transactionId;
      if (id == null) return await repository.addTransaction(input);
      await repository.updateTransaction(id, input);
      return id;
    } finally {
      if (ref.mounted) state = state.copyWith(saving: false);
    }
  }
}
