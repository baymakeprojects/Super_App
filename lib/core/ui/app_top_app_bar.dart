import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_icon.dart';

/// Top App Bar dari Figma (Components [05], node 7:89): ikon kiri, judul,
/// ikon aksi kanan. Dipakai di form dan detail (Close untuk form baru,
/// Arrow Left untuk detail). Ikon yang `null` disembunyikan.
///
/// Bisa dipasang di `Scaffold.appBar`; ruang status bar ditambahkan di atas.
class AppTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopAppBar({
    super.key,
    required this.title,
    this.leadingIcon,
    this.onLeadingPressed,
    this.leadingSemanticLabel,
    this.trailingIcon,
    this.onTrailingPressed,
    this.trailingSemanticLabel,
  });

  /// Tinggi bar di Figma: padding 16 + ikon 24 + padding 16.
  static const double height =
      AppSpace.s16 + AppIcon.defaultSize + AppSpace.s16;

  final String title;

  final AppIcons? leadingIcon;
  final VoidCallback? onLeadingPressed;
  final String? leadingSemanticLabel;

  final AppIcons? trailingIcon;
  final VoidCallback? onTrailingPressed;
  final String? trailingSemanticLabel;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final leadingIcon = this.leadingIcon;
    final trailingIcon = this.trailingIcon;

    return ColoredBox(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              if (leadingIcon != null)
                _BarIcon(
                  icon: leadingIcon,
                  onPressed: onLeadingPressed,
                  semanticLabel: leadingSemanticLabel,
                )
              else
                const SizedBox(width: AppSpace.s16),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.headingSmall.copyWith(color: AppColors.white),
                ),
              ),
              if (trailingIcon != null)
                _BarIcon(
                  icon: trailingIcon,
                  onPressed: onTrailingPressed,
                  semanticLabel: trailingSemanticLabel,
                )
              else
                const SizedBox(width: AppSpace.s16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ikon bar dengan area sentuh 56×56: padding 16 dan jarak 16 di sekitar
/// ikon 24 dari Figma ikut bisa diketuk, tanpa mengubah tampilan.
class _BarIcon extends StatelessWidget {
  const _BarIcon({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  });

  final AppIcons icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: AppTopAppBar.height,
          child: Center(child: AppIcon(icon)),
        ),
      ),
    );
  }
}
