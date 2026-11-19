import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_icon.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Tipe Transaction Item di Figma.
enum AppTransactionType {
  /// Pengeluaran: panah naik-kanan abu, nominal putih.
  expense,

  /// Pemasukan: panah turun hijau, nominal hijau.
  income,
}

/// Transaction Item dari Figma (Components [06], node 8:94): satu transaksi
/// dengan ikon arah uang, judul, meta "DOMPET · KATEGORI · JAM", dan nominal.
/// Garis bawah Dark Gray memisahkan baris dalam daftar.
class AppTransactionItem extends StatelessWidget {
  const AppTransactionItem({
    super.key,
    required this.title,
    required this.meta,
    required this.amount,
    required this.type,
    this.onTap,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _leadingSize = 40;
  static const double _iconSize = 20;
  static const double _borderWidth = 1;

  final String title;

  /// "Tunai · Makan · 07.10". Dikapitalkan otomatis.
  final String meta;

  /// Nominal yang sudah diformat, misalnya "Rp50.000".
  final String amount;

  final AppTransactionType type;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final income = type == AppTransactionType.income;

    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.darkGray,
                width: _borderWidth,
              ),
            ),
          ),
          child: Row(
            spacing: AppSpace.s12,
            children: [
              Container(
                width: _leadingSize,
                height: _leadingSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: AppIcon(
                  income ? AppIcons.arrowDown : AppIcons.arrowUpRight,
                  size: _iconSize,
                  color: income ? AppColors.success : AppColors.lightGray,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpace.s4,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.titleMedium.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    AppLabelText(
                      meta,
                      style: AppText.labelSmall.copyWith(color: AppColors.gray),
                    ),
                  ],
                ),
              ),
              Text(
                amount,
                maxLines: 1,
                style: AppText.titleMedium.copyWith(
                  color: income ? AppColors.success : AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
