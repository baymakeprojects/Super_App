import 'package:flutter/painting.dart';

/// Warna dari variabel Figma (koleksi Palette, mode Dark) di halaman
/// Foundations (node 0:1). Nama mengikuti nama variabel Figma.
///
/// Hanya file di `lib/core/theme` yang boleh menulis `Color(0x...)`.
abstract final class AppColors {
  /// Primary — latar halaman.
  static const Color primary = Color(0xFF000000);

  /// Surface/Raised — kartu dan panel.
  static const Color surfaceRaised = Color(0xFF0D0D0D);

  /// Surface/Card — kartu menonjol, track progress.
  static const Color surfaceCard = Color(0xFF1E1E1E);

  /// Dark Gray — garis dan border.
  static const Color darkGray = Color(0xFF333333);

  /// Gray — label, keterangan, placeholder.
  static const Color gray = Color(0xFF8A8A8A);

  /// Light Gray — teks sekunder.
  static const Color lightGray = Color(0xFFA7A7A7);

  /// White — teks utama.
  static const Color white = Color(0xFFF9F9F9);

  /// Branding Orange — tombol utama, ikon aktif, highlight.
  static const Color brandingOrange = Color(0xFFE85002);

  /// Accent Text — teks oranye kecil.
  static const Color accentText = Color(0xFFE85002);

  /// On Accent — teks dan ikon di atas oranye.
  static const Color onAccent = Color(0xFF000000);

  /// Status/Success — pemasukan, selesai.
  static const Color success = Color(0xFF4FAE68);

  /// Status/Warning — deadline dekat, budget hampir habis.
  static const Color warning = Color(0xFFE3C46A);

  /// Status/Danger — pengeluaran, terlambat, error.
  static const Color danger = Color(0xFFFF5A5F);

  /// Gradient/Sand — gradasi, sorotan.
  static const Color gradientSand = Color(0xFFD9C3AB);

  /// Gradient/Flame — gradasi, tombol hover.
  static const Color gradientFlame = Color(0xFFF16001);

  /// Gradient/Red — gradasi, tombol ditekan.
  static const Color gradientRed = Color(0xFFC10801);

  /// Paint style Gradient/Branding: kiri ke kanan,
  /// Sand 0% → Flame 22% → Red 55% → Primary 100%.
  ///
  /// Hanya dipakai di tempat yang ada di Figma (misalnya kartu Total saldo).
  static const LinearGradient gradientBranding = LinearGradient(
    colors: [gradientSand, gradientFlame, gradientRed, primary],
    stops: [0, 0.22, 0.55, 1],
  );
}
