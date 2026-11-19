import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/db/enums.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/core/utils/money_format.dart';
import 'package:super_app/core/utils/rupiah_input_formatter.dart';
import 'package:super_app/features/keuangan/data/finance_repository.dart';
import 'package:super_app/features/keuangan/data/finance_repository_provider.dart';

/// Keterangan jenis dompet di P06, disalin dari Figma.
String walletKindCaption(WalletKind kind) => switch (kind) {
  WalletKind.cash => 'Uang di dompet',
  WalletKind.bank => 'Rekening tabungan',
  WalletKind.ewallet => 'Dompet digital',
};

/// Hasil P06: dompet dipilih, atau minta membuat dompet baru (P07).
sealed class WalletSheetResult {
  const WalletSheetResult();
}

class WalletPicked extends WalletSheetResult {
  const WalletPicked(this.walletId);

  final String walletId;
}

class AddWalletRequested extends WalletSheetResult {
  const AddWalletRequested();
}

/// P06 Pilih dompet (Figma 51:617). Pilihan bertingkat mengganti sheet:
/// "+ Tambah dompet" menutup P06 lalu pemanggil membuka P07.
Future<WalletSheetResult?> showWalletSheet({
  required BuildContext context,
  required List<WalletBalance> wallets,
  required String? selectedId,
}) {
  return showAppBottomSheet<WalletSheetResult>(
    context: context,
    builder: (_) => WalletSheet(wallets: wallets, selectedId: selectedId),
  );
}

class WalletSheet extends StatelessWidget {
  const WalletSheet({
    super.key,
    required this.wallets,
    required this.selectedId,
  });

  final List<WalletBalance> wallets;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final total = wallets.fold(0, (sum, w) => sum + w.balance);

    return AppBottomSheet(
      title: 'Pilih dompet',
      subtitle: 'Total saldo ${AppMoneyFormat.rupiah(total)}',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.s8,
        children: [
          for (final w in wallets)
            AppOptionItem(
              icon: AppIcons.wallet,
              title: w.wallet.name,
              caption: walletKindCaption(w.wallet.kind),
              value: AppMoneyFormat.rupiah(w.balance),
              selected: w.wallet.id == selectedId,
              onTap: () => navigator.pop(WalletPicked(w.wallet.id)),
            ),
        ],
      ),
      footer: [
        AppButton(
          label: '+ Tambah dompet',
          style: AppButtonStyle.ghost,
          onPressed: () => navigator.pop(const AddWalletRequested()),
        ),
      ],
    );
  }
}

/// P07 Dompet baru (Figma 51:691). Mengembalikan id dompet baru, atau
/// `null` kalau dibatalkan.
///
/// Baris "Hitung di total saldo" disembunyikan: data dompet belum punya
/// kolom untuk itu (keputusan Bayu, W3-04, F-43).
Future<String?> showNewWalletSheet(BuildContext context) {
  return showAppBottomSheet<String>(
    context: context,
    builder: (_) => const NewWalletSheet(),
  );
}

class NewWalletSheet extends ConsumerStatefulWidget {
  const NewWalletSheet({super.key});

  @override
  ConsumerState<NewWalletSheet> createState() => _NewWalletSheetState();
}

class _NewWalletSheetState extends ConsumerState<NewWalletSheet> {
  static const List<(WalletKind, String)> _kinds = [
    (WalletKind.cash, 'Tunai'),
    (WalletKind.bank, 'Bank'),
    (WalletKind.ewallet, 'E-wallet'),
  ];

  final _name = TextEditingController();
  final _opening = TextEditingController();
  WalletKind _kind = WalletKind.cash;
  bool _nameError = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = true);
      return;
    }
    setState(() => _saving = true);
    final id = await ref
        .read(financeRepositoryProvider)
        .addWallet(
          name: name,
          kind: _kind,
          openingBalance: RupiahInputFormatter.parse(_opening.text),
        );
    if (mounted) Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    // Sheet ikut naik saat keyboard muncul.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: AppBottomSheet(
        title: 'Dompet baru',
        subtitle: 'Muncul di Keuangan dan pilihan dompet',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpace.s20,
          children: [
            AppInput(
              label: 'Nama dompet',
              controller: _name,
              autofocus: true,
              textInputAction: TextInputAction.next,
              // Pola G2 (F-43).
              errorText: _nameError ? 'Nama dompet wajib diisi' : null,
              onChanged: (_) {
                if (_nameError) setState(() => _nameError = false);
              },
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpace.s8,
              children: [
                AppLabelText(
                  'Jenis',
                  style: AppText.labelMedium.copyWith(
                    color: AppColors.lightGray,
                  ),
                ),
                Wrap(
                  spacing: AppSpace.s8,
                  runSpacing: AppSpace.s8,
                  children: [
                    for (final (kind, label) in _kinds)
                      AppChip(
                        label: label,
                        selected: kind == _kind,
                        onTap: () => setState(() => _kind = kind),
                      ),
                  ],
                ),
              ],
            ),
            AppInput(
              label: 'Saldo awal',
              placeholder: 'Rp0',
              controller: _opening,
              keyboardType: TextInputType.number,
              inputFormatters: const [RupiahInputFormatter()],
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        footer: [
          AppButton(
            label: 'Batal',
            style: AppButtonStyle.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
          AppButton(label: 'Simpan dompet', onPressed: _saving ? null : _save),
        ],
      ),
    );
  }
}
