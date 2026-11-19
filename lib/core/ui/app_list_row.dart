import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_icon.dart';
import 'package:super_app/core/ui/app_label_text.dart';
import 'package:super_app/core/ui/app_switch.dart';

/// List Row dari Figma (Components, node 21:99): ikon dalam kotak 36,
/// judul, subjudul, lalu chevron, switch, atau nilai di kanan. Garis Dark
/// Gray di bawah. Ditumpuk di dalam grup (01a, 01c, 14).
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing = const AppListRowChevron(),
    this.onTap,
    this.horizontalPadding = AppSpace.s16,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _leadingSize = 36;
  static const double _iconSize = 20;
  static const double _textGap = 2;

  final AppIcons icon;
  final String title;

  /// `null` = tanpa subjudul.
  final String? subtitle;

  /// [AppListRowChevron], [AppListRowSwitch], atau [AppListRowValue].
  final Widget trailing;
  final VoidCallback? onTap;

  /// Padding kiri-kanan: 16 di komponen, 0 di layar setup 01a–01c.
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: AppSpace.s12,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.darkGray)),
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
              child: AppIcon(icon, size: _iconSize),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: _textGap,
                children: [
                  Text(
                    title,
                    style: AppText.titleMedium.copyWith(color: AppColors.white),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: AppText.bodySmall.copyWith(color: AppColors.gray),
                    ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// Chevron abu di kanan List Row (Trailing=Chevron).
class AppListRowChevron extends StatelessWidget {
  const AppListRowChevron({super.key});

  static const double _size = 20;

  @override
  Widget build(BuildContext context) =>
      const AppIcon(AppIcons.chevronRight, color: AppColors.gray, size: _size);
}

/// Switch di kanan List Row (Trailing=Switch).
class AppListRowSwitch extends StatelessWidget {
  const AppListRowSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) =>
      AppSwitch(value: value, onChanged: onChanged);
}

/// Nilai kecil kapital di kanan List Row (Trailing=Value), misalnya jam.
class AppListRowValue extends StatelessWidget {
  const AppListRowValue(this.value, {super.key});

  final String value;

  @override
  Widget build(BuildContext context) => AppLabelText(
    value,
    style: AppText.labelSmall.copyWith(color: AppColors.lightGray),
  );
}
