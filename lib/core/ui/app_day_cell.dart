import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';

/// Keadaan Day Cell di Figma.
enum AppDayCellState {
  /// Tanggal biasa di bulan ini.
  normal,

  /// Tanggal bulan sebelum/sesudah (abu gelap).
  muted,

  /// Hari ini: lingkaran garis oranye.
  today,

  /// Terpilih: lingkaran isi oranye.
  selected,

  /// Di dalam rentang tanggal: isi Surface/Card.
  inRange,
}

/// Day Cell dari Figma (Components [09], node 49:188): satu tanggal bulat
/// 40px di Date Picker.
class AppDayCell extends StatelessWidget {
  const AppDayCell({
    super.key,
    required this.day,
    required this.state,
    this.onTap,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double size = 40;
  static const double _borderWidth = 1;

  /// Angka tanggal, misalnya "6".
  final String day;

  final AppDayCellState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color? fill, Color? border, Color text) = switch (state) {
      AppDayCellState.normal => (null, null, AppColors.white),
      AppDayCellState.muted => (null, null, AppColors.darkGray),
      AppDayCellState.today => (
        null,
        AppColors.brandingOrange,
        AppColors.accentText,
      ),
      AppDayCellState.selected => (
        AppColors.brandingOrange,
        null,
        AppColors.onAccent,
      ),
      AppDayCellState.inRange => (AppColors.surfaceCard, null, AppColors.white),
    };

    return Semantics(
      button: onTap != null,
      selected: state == AppDayCellState.selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: border == null
                ? null
                : Border.all(color: border, width: _borderWidth),
          ),
          child: Text(
            day,
            maxLines: 1,
            style: AppText.bodyMedium.copyWith(color: text),
          ),
        ),
      ),
    );
  }
}
