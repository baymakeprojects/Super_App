import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Gaya Button di Figma (Components [02], node 6:24).
enum AppButtonStyle {
  /// Tombol utama oranye.
  primary,

  /// Tombol garis.
  ghost,

  /// Hanya untuk hapus dan keluar akun. Figma baru punya keadaan Default,
  /// jadi tampilannya tidak berubah saat hover, ditekan, atau nonaktif.
  danger,
}

/// Keadaan Button di Figma. Di layar, keadaan muncul sendiri dari interaksi.
enum AppButtonState { normal, hover, pressed, disabled }

/// Button dari Figma: sudut 12, label Geist Mono kapital.
///
/// Sesuai catatan Figma, tombol melebar penuh di layar HP ([expand] = true)
/// dengan label di tengah. Hover hanya muncul di desktop.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.expand = true,
    this.previewState,
  });

  /// Teks tombol, disalin persis dari Figma. Dikapitalkan otomatis.
  final String label;

  /// `null` = tombol nonaktif (Disabled).
  final VoidCallback? onPressed;

  final AppButtonStyle style;

  /// `true` = selebar induknya; `false` = selebar isinya.
  final bool expand;

  /// Paksa tampilan keadaan tertentu. Hanya untuk katalog dan golden test;
  /// di layar biarkan `null`.
  final AppButtonState? previewState;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  static const double _borderWidth = 1;

  bool _hovered = false;
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  AppButtonState get _state {
    if (widget.previewState case final state?) return state;
    if (!_enabled) return AppButtonState.disabled;
    if (_pressed) return AppButtonState.pressed;
    if (_hovered) return AppButtonState.hover;
    return AppButtonState.normal;
  }

  _ButtonColors get _colors {
    final state = _state;
    switch (widget.style) {
      case AppButtonStyle.primary:
        return switch (state) {
          AppButtonState.normal => const _ButtonColors(
            fill: AppColors.brandingOrange,
            border: AppColors.brandingOrange,
            label: AppColors.onAccent,
          ),
          AppButtonState.hover => const _ButtonColors(
            fill: AppColors.gradientFlame,
            border: AppColors.gradientFlame,
            label: AppColors.onAccent,
          ),
          AppButtonState.pressed => const _ButtonColors(
            fill: AppColors.gradientRed,
            border: AppColors.gradientRed,
            label: AppColors.white,
          ),
          AppButtonState.disabled => const _ButtonColors(
            fill: AppColors.surfaceCard,
            border: AppColors.surfaceCard,
            label: AppColors.gray,
          ),
        };
      case AppButtonStyle.ghost:
        return switch (state) {
          AppButtonState.normal => const _ButtonColors(
            border: AppColors.gray,
            label: AppColors.white,
          ),
          AppButtonState.hover => const _ButtonColors(
            border: AppColors.brandingOrange,
            label: AppColors.accentText,
          ),
          AppButtonState.pressed => const _ButtonColors(
            fill: AppColors.darkGray,
            border: AppColors.brandingOrange,
            label: AppColors.white,
          ),
          AppButtonState.disabled => const _ButtonColors(
            border: AppColors.darkGray,
            label: AppColors.gray,
          ),
        };
      case AppButtonStyle.danger:
        return const _ButtonColors(
          fill: AppColors.danger,
          border: AppColors.danger,
          label: AppColors.onAccent,
        );
    }
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors;

    return Semantics(
      button: true,
      enabled: _enabled,
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: _enabled ? (_) => _setPressed(true) : null,
          onTapUp: _enabled ? (_) => _setPressed(false) : null,
          onTapCancel: _enabled ? () => _setPressed(false) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s24,
              vertical: AppSpace.s16,
            ),
            decoration: BoxDecoration(
              color: colors.fill,
              border: Border.all(color: colors.border, width: _borderWidth),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: widget.expand
                // Seperti di Figma, label panjang di tombol lebar penuh boleh
                // masuk ke padding kiri-kanan dan tetap di tengah (misalnya
                // "Simpan perubahan" di Action Bar Double H01).
                ? LayoutBuilder(
                    builder: (context, constraints) => Center(
                      heightFactor: 1,
                      child: OverflowBox(
                        fit: OverflowBoxFit.deferToChild,
                        maxWidth: constraints.maxWidth + 2 * AppSpace.s24,
                        child: AppLabelText(
                          widget.label,
                          style: AppText.labelLarge.copyWith(
                            color: colors.label,
                          ),
                        ),
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: AppLabelText(
                          widget.label,
                          style: AppText.labelLarge.copyWith(
                            color: colors.label,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ButtonColors {
  const _ButtonColors({this.fill, required this.border, required this.label});

  /// `null` = tanpa isi (transparan).
  final Color? fill;
  final Color border;
  final Color label;
}
