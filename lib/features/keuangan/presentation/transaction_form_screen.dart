import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/db/enums.dart';
import 'package:super_app/core/sheets/date_sheet.dart';
import 'package:super_app/core/sheets/time_sheet.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/core/utils/date_format.dart';
import 'package:super_app/core/utils/money_format.dart';
import 'package:super_app/core/utils/rupiah_input_formatter.dart';
import 'package:super_app/features/keuangan/application/finance_snackbar.dart';
import 'package:super_app/features/keuangan/application/keuangan_providers.dart';
import 'package:super_app/features/keuangan/application/transaction_form_controller.dart';
import 'package:super_app/features/keuangan/data/finance_repository.dart';
import 'package:super_app/features/keuangan/presentation/wallet_sheets.dart';

/// Layar 17 Transaksi baru (Figma 31:1482) dengan P06 Pilih dompet,
/// P07 Dompet baru, P01 tanggal, dan P02 jam. Juga H11 Ubah transaksi
/// (W3-05) lewat [transactionId].
class TransactionFormScreen extends ConsumerWidget {
  const TransactionFormScreen({super.key, this.transactionId});

  /// `null` = Transaksi baru.
  final String? transactionId;

  static const String newTitle = 'Transaksi baru';
  static const String editTitle = 'Ubah transaksi';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = transactionId;
    final categoriesReady = ref.watch(defaultCategoriesProvider).hasValue;
    final sourceReady =
        id == null ||
        ref.watch(transactionEditSourceProvider(id)).value != null;
    if (!categoriesReady || !sourceReady) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppTopAppBar(
          title: id == null ? newTitle : editTitle,
          leadingIcon: AppIcons.close,
          leadingSemanticLabel: 'Tutup',
          onLeadingPressed: () => context.pop(),
        ),
      );
    }
    return _TransactionForm(transactionId: id);
  }
}

class _TransactionForm extends ConsumerStatefulWidget {
  const _TransactionForm({required this.transactionId});

  final String? transactionId;

  @override
  ConsumerState<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<_TransactionForm> {
  late final _provider = transactionFormProvider(widget.transactionId);
  late final _amount = TextEditingController(
    text: RupiahInputFormatter.format(ref.read(_provider).amount),
  );
  late final _notes = TextEditingController(text: ref.read(_provider).notes);

  bool get _isEdit => widget.transactionId != null;

  TransactionFormController get _form => ref.read(_provider.notifier);

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _unfocus() => FocusScope.of(context).unfocus();

  Future<void> _pickWallet() async {
    _unfocus();
    final wallets = ref.read(walletsProvider).value ?? const [];
    final selected =
        ref.read(_provider).walletId ??
        (wallets.isEmpty ? null : wallets.first.wallet.id);
    final result = await showWalletSheet(
      context: context,
      wallets: wallets,
      selectedId: selected,
    );
    if (!mounted) return;
    switch (result) {
      case WalletPicked(:final walletId):
        _form.setWallet(walletId);
      case AddWalletRequested():
        // Pilihan bertingkat mengganti sheet: P06 tertutup, P07 terbuka.
        final id = await showNewWalletSheet(context);
        if (id != null) _form.setWallet(id);
      case null:
        break;
    }
  }

  Future<void> _pickDate() async {
    _unfocus();
    final result = await showDateSheet(
      context: context,
      selected: ref.read(_provider).date,
      today: ref.read(clockProvider)(),
      subtitle: 'Tanggal transaksi',
      allowNoDate: false,
    );
    final date = result?.date;
    if (date != null) _form.setDate(date);
  }

  Future<void> _pickTime() async {
    _unfocus();
    final form = ref.read(_provider);
    final result = await showTimeSheet(
      context: context,
      selected: (hour: form.hour, minute: form.minute),
      subtitle: 'Jam transaksi · ${_dateLabel(form.date)}',
    );
    if (result != null) _form.setTime(result.hour, result.minute);
  }

  /// P47 Hapus transaksi, lalu kembali ke 05 dengan snackbar Urungkan.
  Future<void> _confirmDelete() async {
    _unfocus();
    final id = widget.transactionId;
    final item = id == null
        ? null
        : ref.read(transactionEditSourceProvider(id)).value;
    if (id == null || item == null) return;
    final row = transactionRowOf(item, ref.read(clockProvider)());
    final confirmed = await showAppBottomSheet<bool>(
      context: context,
      builder: (_) => DeleteTransactionSheet(
        message: deleteTransactionMessage(item, row.title),
      ),
    );
    if (confirmed != true || !mounted) return;
    final snackbar = ref.read(financeSnackbarProvider.notifier);
    context.pop();
    await snackbar.delete(id, row.title);
  }

  /// "Hari ini" seperti Figma; tanggal lain "Jum, 6 Nov".
  String _dateLabel(DateTime date) {
    final today = ref.read(clockProvider)();
    return AppDateFormat.daysBetween(today, date) == 0
        ? 'Hari ini'
        : AppDateFormat.weekdayShortDayMonth(date);
  }

  List<Wallet> _wallets() => [
    for (final w in ref.read(walletsProvider).value ?? const <WalletBalance>[])
      w.wallet,
  ];

  Future<void> _save(List<Category> categories) async {
    if (_wallets().isEmpty) {
      // Belum ada dompet: buat dulu lewat P07.
      final id = await showNewWalletSheet(context);
      if (id == null || !mounted) return;
      _form.setWallet(id);
    }
    final id = await _form.save(categories: categories, wallets: _wallets());
    if (id != null && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(_provider);
    final categories =
        ref.watch(categoriesProvider(form.kind)).value ?? const [];
    final wallets = ref.watch(walletsProvider).value ?? const [];
    final selectedCategory =
        form.categoryId ?? (categories.isEmpty ? null : categories.first.id);
    final selectedWallet = wallets
        .where((w) => w.wallet.id == form.walletId)
        .followedBy(wallets)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppTopAppBar(
        title: _isEdit
            ? TransactionFormScreen.editTitle
            : TransactionFormScreen.newTitle,
        leadingIcon: AppIcons.close,
        leadingSemanticLabel: 'Tutup',
        onLeadingPressed: () => context.pop(),
        // H11: ikon Hapus di kanan atas membuka P47.
        trailingIcon: _isEdit ? AppIcons.trash : null,
        trailingSemanticLabel: 'Hapus transaksi',
        onTrailingPressed: _confirmDelete,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s20,
          AppSpace.s8,
          AppSpace.s20,
          AppSpace.s24,
        ),
        children: [
          AppSegmentedControl(
            firstLabel: 'Pengeluaran',
            secondLabel: 'Pemasukan',
            selectedIndex: form.kind == MoneyKind.expense ? 0 : 1,
            onChanged: (i) =>
                _form.setKind(i == 0 ? MoneyKind.expense : MoneyKind.income),
          ),
          const SizedBox(height: AppSpace.s20),
          _AmountField(
            controller: _amount,
            autofocus: !_isEdit,
            error: form.showAmountError,
            onChanged: (text) =>
                _form.setAmount(RupiahInputFormatter.parse(text)),
          ),
          const SizedBox(height: AppSpace.s20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.s8,
            children: [
              AppLabelText(
                'Kategori',
                style: AppText.labelMedium.copyWith(color: AppColors.lightGray),
              ),
              Wrap(
                spacing: AppSpace.s8,
                runSpacing: AppSpace.s8,
                children: [
                  for (final c in categories)
                    AppChip(
                      label: c.name,
                      selected: c.id == selectedCategory,
                      onTap: () => _form.setCategory(c.id),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s20),
          AppSelect(
            label: 'Dompet',
            value: selectedWallet?.wallet.name,
            placeholder: 'Pilih dompet',
            onTap: _pickWallet,
          ),
          const SizedBox(height: AppSpace.s20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.s12,
            children: [
              Expanded(
                child: AppSelect(
                  label: 'Tanggal',
                  value: _dateLabel(form.date),
                  icon: AppIcons.calendar,
                  onTap: _pickDate,
                ),
              ),
              Expanded(
                child: AppSelect(
                  label: 'Jam',
                  value: AppDateFormat.time(form.occurredAt),
                  icon: AppIcons.clock,
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s20),
          AppInput(
            label: 'Catatan',
            placeholder: 'Tambahkan catatan (opsional)',
            controller: _notes,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            onChanged: _form.setNotes,
          ),
        ],
      ),
      bottomNavigationBar: _isEdit
          ? AppActionBar(
              secondaryLabel: 'Batal',
              onSecondaryPressed: () => context.pop(),
              primaryLabel: 'Simpan perubahan',
              onPrimaryPressed: form.saving ? null : () => _save(categories),
            )
          : AppActionBar(
              primaryLabel: 'Simpan transaksi',
              onPrimaryPressed: form.saving ? null : () => _save(categories),
            ),
    );
  }
}

/// Kolom Nominal 17: angka Doto besar dengan garis bawah 2px, keyboard
/// angka (design-notes §6). Garis oranye saat fokus, merah saat error.
class _AmountField extends StatefulWidget {
  const _AmountField({
    required this.controller,
    required this.autofocus,
    required this.error,
    required this.onChanged,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma): tebal garis fokus.
  static const double _lineHeight = 2;

  final TextEditingController controller;
  final bool autofocus;
  final bool error;
  final ValueChanged<String> onChanged;

  @override
  State<_AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<_AmountField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lineColor = widget.error
        ? AppColors.danger
        : _focus.hasFocus
        ? AppColors.brandingOrange
        : AppColors.darkGray;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s8,
      children: [
        AppLabelText(
          'Nominal',
          style: AppText.labelMedium.copyWith(
            color: widget.error ? AppColors.danger : AppColors.lightGray,
          ),
        ),
        Material(
          type: MaterialType.transparency,
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            autofocus: widget.autofocus,
            keyboardType: TextInputType.number,
            inputFormatters: const [RupiahInputFormatter()],
            onChanged: widget.onChanged,
            style: AppText.displayLarge.copyWith(color: AppColors.white),
            cursorColor: AppColors.brandingOrange,
            decoration: InputDecoration.collapsed(
              hintText: 'Rp0',
              hintStyle: AppText.displayLarge.copyWith(
                color: AppColors.darkGray,
              ),
            ),
          ),
        ),
        Container(height: _AmountField._lineHeight, color: lineColor),
        // Pola G2 (F-43).
        if (widget.error)
          Text(
            'Nominal wajib diisi',
            style: AppText.bodySmall.copyWith(color: AppColors.danger),
          ),
      ],
    );
  }
}

/// Teks P47 (Figma 185:13574). "dari HP dan desktop" dihapus karena
/// desktop baru Tahap 2 (keputusan Bayu, W3-05, F-44).
String deleteTransactionMessage(TransactionListItem item, String title) {
  final t = item.transaction;
  final income = t.kind == MoneyKind.income;
  final amount = AppMoneyFormat.rupiah(t.amount);
  final wallet = item.walletName;
  final balance = wallet == null
      ? ''
      : ', dan saldo $wallet ${income ? 'berkurang' : 'bertambah lagi'} '
            '$amount';
  return '“$title” (${AppMoneyFormat.signed(t.amount, income: income)}) '
      'akan dihapus$balance. Setelah dihapus, kamu masih bisa '
      'mengurungkannya dari snackbar.';
}

/// P47: tanpa tombol tutup, Batal + Hapus transaksi (Danger). Mengembalikan
/// `true` kalau Hapus transaksi diketuk.
class DeleteTransactionSheet extends StatelessWidget {
  const DeleteTransactionSheet({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return AppBottomSheet(
      title: 'Hapus transaksi ini?',
      showClose: false,
      body: Text(
        message,
        style: AppText.bodyLarge.copyWith(color: AppColors.lightGray),
      ),
      footer: [
        AppButton(
          label: 'Batal',
          style: AppButtonStyle.ghost,
          onPressed: () => navigator.pop(false),
        ),
        AppButton(
          label: 'Hapus transaksi',
          style: AppButtonStyle.danger,
          onPressed: () => navigator.pop(true),
        ),
      ],
    );
  }
}
