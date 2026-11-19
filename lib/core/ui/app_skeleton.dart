import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';

/// Kotak abu pengganti isi selama data belum siap (E7 Memuat, Figma
/// 68:2289): Surface/Card dengan opacity 90%.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.card,
  });

  /// Sudut kotak teks di E7 (bukan variabel Figma, F-56).
  static const double lineRadius = 4;
  static const double labelRadius = 6;

  static const double _opacity = 0.9;

  /// `null` = selebar ruang.
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Satu baris daftar yang sedang dimuat (E7 "Baris", 68:2336): kotak 24
/// dan dua garis teks di dalam bingkai garis Dark Gray.
class AppSkeletonRow extends StatelessWidget {
  const AppSkeletonRow({super.key});

  // Ukuran tetap dari Figma (bukan variabel Figma, F-56).
  static const double _leading = 24;
  static const double _titleWidth = 200;
  static const double _titleHeight = 14;
  static const double _metaWidth = 140;
  static const double _metaHeight = 10;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.s16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.item),
        border: Border.all(color: AppColors.darkGray),
      ),
      child: const Row(
        spacing: AppSpace.s12,
        children: [
          AppSkeleton(
            width: _leading,
            height: _leading,
            radius: AppSkeleton.labelRadius,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.s8,
              children: [
                AppSkeleton(
                  width: _titleWidth,
                  height: _titleHeight,
                  radius: AppSkeleton.lineRadius,
                ),
                AppSkeleton(
                  width: _metaWidth,
                  height: _metaHeight,
                  radius: AppSkeleton.lineRadius,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bagian daftar yang sedang dimuat (E7 "Daftar", 68:2334): judul abu
/// lalu [rows] baris.
class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({super.key, this.rows = 3});

  static const double _labelWidth = 140;
  static const double _labelHeight = 18;

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s12,
      children: [
        const AppSkeleton(
          width: _labelWidth,
          height: _labelHeight,
          radius: AppSkeleton.labelRadius,
        ),
        for (var i = 0; i < rows; i++) const AppSkeletonRow(),
      ],
    );
  }
}

/// Isi layar yang sedang dimuat untuk layar selain Beranda (E7 hanya
/// didesain di Beranda, F-56): padding isi layar lalu [AppSkeletonList].
class AppSkeletonPage extends StatelessWidget {
  const AppSkeletonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpace.s20,
          AppSpace.s12,
          AppSpace.s20,
          AppSpace.s24,
        ),
        child: AppSkeletonList(),
      ),
    );
  }
}
