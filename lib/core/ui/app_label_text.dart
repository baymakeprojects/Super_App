import 'package:material_ui/material_ui.dart';

/// Teks label kapital (gaya Label/Large, Medium, Small Figma).
///
/// - Teks disimpan huruf biasa dan dikapitalkan di sini (design-notes §3).
/// - Figma tidak menambah letter spacing setelah huruf terakhir, Flutter
///   menambahkannya. Huruf terakhir diberi letter spacing 0 supaya lebar
///   label (dan komponen yang memeluknya, seperti Chip dan Badge) sama
///   dengan Figma.
class AppLabelText extends StatelessWidget {
  const AppLabelText(
    this.text, {
    super.key,
    required this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
  });

  final String text;

  /// Gaya Label dari `AppText`, sudah dengan warnanya.
  final TextStyle style;

  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final upper = text.toUpperCase().characters;
    if (upper.isEmpty) return Text('', style: style);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: upper.skipLast(1).string),
          TextSpan(text: upper.last, style: const TextStyle(letterSpacing: 0)),
        ],
      ),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}
