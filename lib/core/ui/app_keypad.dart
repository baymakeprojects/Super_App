import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_icon.dart';

/// Keypad dari Figma (Components, node 49:323): keypad PIN 6 angka.
/// Baris bawah: sidik jari (bisa disembunyikan, misalnya di layar Atur PIN),
/// 0, dan Hapus.
class AppKeypad extends StatelessWidget {
  const AppKeypad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.onFingerprint,
    this.showFingerprint = true,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double keyHeight = 64;
  static const double _fingerprintSize = 28;

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onFingerprint;
  final bool showFingerprint;

  @override
  Widget build(BuildContext context) {
    Widget digit(String value) => _Key(
      filled: true,
      onTap: () => onDigit(value),
      semanticLabel: value,
      child: Text(
        value,
        style: AppText.headingMedium.copyWith(color: AppColors.white),
      ),
    );

    Widget row(List<Widget> keys) => Row(
      spacing: AppSpace.s12,
      children: [for (final key in keys) Expanded(child: key)],
    );

    return Column(
      spacing: AppSpace.s12,
      children: [
        row([digit('1'), digit('2'), digit('3')]),
        row([digit('4'), digit('5'), digit('6')]),
        row([digit('7'), digit('8'), digit('9')]),
        row([
          _Key(
            onTap: showFingerprint ? onFingerprint : null,
            semanticLabel: showFingerprint ? 'Sidik jari' : null,
            child: showFingerprint
                ? const AppIcon(
                    AppIcons.fingerprint,
                    color: AppColors.brandingOrange,
                    size: _fingerprintSize,
                  )
                : null,
          ),
          digit('0'),
          _Key(
            onTap: onDelete,
            semanticLabel: 'Hapus',
            child: const AppIcon(
              AppIcons.arrowLeft,
              color: AppColors.lightGray,
            ),
          ),
        ]),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.onTap,
    required this.child,
    this.filled = false,
    this.semanticLabel,
  });

  final VoidCallback? onTap;
  final Widget? child;
  final bool filled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.item);
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: filled ? AppColors.surfaceCard : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            height: AppKeypad.keyHeight,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Enam titik PIN di H06 (node 56:2612): terisi oranye, kosong bergaris abu.
class AppPinDots extends StatelessWidget {
  const AppPinDots({super.key, required this.filled, this.length = 6});

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _dotSize = 14;
  static const double _gap = 16;
  static const double _borderWidth = 1.5;

  /// Jumlah digit yang sudah diketik.
  final int filled;
  final int length;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: _gap,
      children: [
        for (var i = 0; i < length; i++)
          Container(
            width: _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? AppColors.brandingOrange : null,
              border: i < filled
                  ? null
                  : Border.all(color: AppColors.gray, width: _borderWidth),
            ),
          ),
      ],
    );
  }
}
