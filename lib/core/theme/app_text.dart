import 'package:flutter/painting.dart';

/// 13 gaya teks dari halaman Foundations (node 0:1).
///
/// - `height` = tinggi baris Figma ÷ ukuran huruf.
/// - `leadingDistribution: even` membagi ruang baris rata di atas dan bawah,
///   sama seperti Figma.
/// - Font berupa variable font, jadi ketebalan diisi di `fontWeight` dan
///   `fontVariations` sekaligus.
/// - Gaya Label disimpan tanpa kapital; widget yang mengubah teksnya
///   jadi kapital.
/// - Warna tidak diisi di sini; diberikan oleh tema atau widget.
abstract final class AppText {
  static const String doto = 'Doto';
  static const String geist = 'Geist';
  static const String geistMono = 'GeistMono';

  static const List<FontVariation> _dotoBlack = [
    FontVariation('wght', 900),
    FontVariation('ROND', 0),
  ];
  static const List<FontVariation> _regular = [FontVariation('wght', 400)];
  static const List<FontVariation> _medium = [FontVariation('wght', 500)];
  static const List<FontVariation> _semiBold = [FontVariation('wght', 600)];

  /// Display/Large — Doto Black 48/48, −1.
  static const TextStyle displayLarge = TextStyle(
    fontFamily: doto,
    fontWeight: FontWeight.w900,
    fontVariations: _dotoBlack,
    fontSize: 48,
    height: 48 / 48,
    letterSpacing: -1,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Display/Medium — Doto Black 36/38.
  static const TextStyle displayMedium = TextStyle(
    fontFamily: doto,
    fontWeight: FontWeight.w900,
    fontVariations: _dotoBlack,
    fontSize: 36,
    height: 38 / 36,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Display/Small — Doto Black 28/30.
  static const TextStyle displaySmall = TextStyle(
    fontFamily: doto,
    fontWeight: FontWeight.w900,
    fontVariations: _dotoBlack,
    fontSize: 28,
    height: 30 / 28,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Heading/Large — Geist Medium 28/34, −0,8.
  static const TextStyle headingLarge = TextStyle(
    fontFamily: geist,
    fontWeight: FontWeight.w500,
    fontVariations: _medium,
    fontSize: 28,
    height: 34 / 28,
    letterSpacing: -0.8,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Heading/Medium — Geist Medium 22/28, −0,3.
  static const TextStyle headingMedium = TextStyle(
    fontFamily: geist,
    fontWeight: FontWeight.w500,
    fontVariations: _medium,
    fontSize: 22,
    height: 28 / 22,
    letterSpacing: -0.3,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Heading/Small — Geist Medium 18/24, −0,2.
  static const TextStyle headingSmall = TextStyle(
    fontFamily: geist,
    fontWeight: FontWeight.w500,
    fontVariations: _medium,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: -0.2,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Title/Medium — Geist Medium 16/22.
  static const TextStyle titleMedium = TextStyle(
    fontFamily: geist,
    fontWeight: FontWeight.w500,
    fontVariations: _medium,
    fontSize: 16,
    height: 22 / 16,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Body/Large — Geist Regular 16/24.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: geist,
    fontWeight: FontWeight.w400,
    fontVariations: _regular,
    fontSize: 16,
    height: 24 / 16,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Body/Medium — Geist Regular 14/20.
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: geist,
    fontWeight: FontWeight.w400,
    fontVariations: _regular,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Body/Small — Geist Regular 12/16.
  static const TextStyle bodySmall = TextStyle(
    fontFamily: geist,
    fontWeight: FontWeight.w400,
    fontVariations: _regular,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Label/Large — Geist Mono SemiBold 13/18, +1, kapital.
  static const TextStyle labelLarge = TextStyle(
    fontFamily: geistMono,
    fontWeight: FontWeight.w600,
    fontVariations: _semiBold,
    fontSize: 13,
    height: 18 / 13,
    letterSpacing: 1,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Label/Medium — Geist Mono Regular 11/16, +1,5, kapital.
  static const TextStyle labelMedium = TextStyle(
    fontFamily: geistMono,
    fontWeight: FontWeight.w400,
    fontVariations: _regular,
    fontSize: 11,
    height: 16 / 11,
    letterSpacing: 1.5,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Label/Small — Geist Mono Regular 10/14, +1,5, kapital.
  static const TextStyle labelSmall = TextStyle(
    fontFamily: geistMono,
    fontWeight: FontWeight.w400,
    fontVariations: _regular,
    fontSize: 10,
    height: 14 / 10,
    letterSpacing: 1.5,
    leadingDistribution: TextLeadingDistribution.even,
  );
}
