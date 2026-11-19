import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Wallet Card dari Figma (Components [06], node 9:82): saldo satu dompet
/// (tunai, bank, e-wallet). Nama dompet kapital, lalu saldo.
class AppWalletCard extends StatelessWidget {
  const AppWalletCard({
    super.key,
    required this.label,
    required this.amount,
    this.onTap,
  });

  /// Lebar kartu di Figma.
  static const double width = 140;
  static const double _borderWidth = 1;

  /// Nama dompet, misalnya "Tunai". Dikapitalkan otomatis.
  final String label;

  /// Saldo yang sudah diformat, misalnya "Rp150.000".
  final String amount;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: width,
          padding: const EdgeInsets.all(AppSpace.s16),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            border: Border.all(color: AppColors.darkGray, width: _borderWidth),
            borderRadius: BorderRadius.circular(AppRadius.item),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.s8,
            children: [
              AppLabelText(
                label,
                style: AppText.labelSmall.copyWith(color: AppColors.gray),
              ),
              // Nominal tidak boleh terpotong: kalau kartu sempit (tiga
              // sejajar di 05), teks mengecil secukupnya.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  maxLines: 1,
                  style: AppText.titleMedium.copyWith(color: AppColors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
