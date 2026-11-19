import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_overlay_header.dart';

/// Kerangka bottom sheet pop-up P (frame "Sheet" di P01, P02, P03):
/// latar Surface/Raised, garis atas Dark Gray, sudut atas 20, Overlay
/// Header, isi, lalu footer tombol.
///
/// Di Figma kerangka ini belum jadi komponen, hanya frame di tiap pop-up
/// (F-27); ukurannya disalin dari sana.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.footer = const [],
    this.onClose,
    this.showClose = true,
  });

  static const double _borderWidth = 1;

  final String title;
  final String? subtitle;

  /// Isi pop-up (kalender, roda jam, daftar pilihan).
  final Widget body;

  /// Tombol di bawah, berjajar dengan lebar sama (misalnya Batal + Pilih).
  /// Kosong = tanpa footer.
  final List<Widget> footer;

  /// Tombol tutup bulat di kepala. Bawaan: menutup sheet tanpa hasil.
  final VoidCallback? onClose;

  /// `false` = tanpa tombol tutup, misalnya konfirmasi hapus (design-notes
  /// §4: konfirmasi hapus tanpa tombol tutup).
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final systemBottom = media.viewPadding.bottom;
    final paddedBody = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s24,
        AppSpace.s8,
        AppSpace.s24,
        AppSpace.s16,
      ),
      child: body,
    );

    return Container(
      width: double.infinity,
      // Sheet paling tinggi sampai bawah status bar; isi yang lebih panjang
      // (daftar mata kuliah) digulir, kepala dan footer tetap.
      constraints: BoxConstraints(
        maxHeight: media.size.height - media.viewPadding.top,
      ),
      padding: EdgeInsets.only(bottom: AppSpace.s8 + systemBottom),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(
          top: BorderSide(color: AppColors.darkGray, width: _borderWidth),
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppOverlayHeader(
            title: title,
            subtitle: subtitle,
            onClose: showClose
                ? onClose ?? () => Navigator.of(context).pop()
                : null,
          ),
          Flexible(child: SingleChildScrollView(child: paddedBody)),
          if (footer.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s24,
                AppSpace.s8,
                AppSpace.s24,
                AppSpace.s16,
              ),
              child: Row(
                spacing: AppSpace.s12,
                children: [
                  for (final button in footer) Expanded(child: button),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Opacity scrim hitam di belakang sheet (design-notes §4: "scrim hitam
/// 70%").
const double _scrimOpacity = 0.7;

/// Buka pop-up P sebagai bottom sheet: lebar penuh, scrim hitam 70%,
/// tanpa bayangan Material. Hasilnya `null` kalau ditutup tanpa memilih.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: AppColors.primary.withValues(alpha: _scrimOpacity),
    constraints: const BoxConstraints(),
  );
}
