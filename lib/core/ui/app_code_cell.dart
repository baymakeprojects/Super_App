import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';

/// Keadaan Code Cell di Figma.
enum AppCodeCellState {
  /// Belum diisi: garis Dark Gray.
  empty,

  /// Kotak yang sedang diketik: garis oranye dan kursor.
  focus,

  /// Sudah berisi angka.
  filled,

  /// Kode salah atau kedaluwarsa: garis merah, angka tetap tampil.
  error,
}

/// Code Cell dari Figma (Components, node 229:241): satu digit kode
/// verifikasi email. Enam kotak berjajar dengan jarak 8 dan lebar FILL
/// (layar 00f Masukkan kode).
class AppCodeCell extends StatelessWidget {
  const AppCodeCell({super.key, required this.state, this.digit = ''});

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double height = 64;
  static const double _borderWidth = 1;
  static const double _cursorWidth = 2;
  static const double _cursorHeight = 28;

  final AppCodeCellState state;

  /// Angka di kotak; dipakai saat [state] filled atau error.
  final String digit;

  @override
  Widget build(BuildContext context) {
    final border = switch (state) {
      AppCodeCellState.empty || AppCodeCellState.filled => AppColors.darkGray,
      AppCodeCellState.focus => AppColors.brandingOrange,
      AppCodeCellState.error => AppColors.danger,
    };
    final Widget? content = switch (state) {
      AppCodeCellState.empty => null,
      AppCodeCellState.focus => const SizedBox(
        width: _cursorWidth,
        height: _cursorHeight,
        child: ColoredBox(color: AppColors.brandingOrange),
      ),
      AppCodeCellState.filled || AppCodeCellState.error => Text(
        digit,
        textAlign: TextAlign.center,
        style: AppText.displaySmall.copyWith(color: AppColors.white),
      ),
    };

    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: border, width: _borderWidth),
      ),
      child: content,
    );
  }
}
