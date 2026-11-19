// Membuat gambar ikon app dan splash Android dari desain Figma (W4-03):
// "Ikon app" (66:1983) dan "00 Splash" (66:1977).
//
// Jalankan ulang hanya kalau desain ikon atau splash berubah:
//   flutter test tool/launcher_assets_test.dart
//
// Gambar digambar dengan widget dan font app sendiri (Geist Mono), lalu
// disimpan sebagai PNG di android/app/src/main/res untuk setiap kepadatan
// layar. Tidak perlu paket tambahan.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';

import '../test/helpers/app_fonts.dart';

const String _res = 'android/app/src/main/res';

/// Kepadatan layar Android dan skalanya terhadap dp.
const Map<String, double> _densities = {
  'mdpi': 1,
  'hdpi': 1.5,
  'xhdpi': 2,
  'xxhdpi': 3,
  'xxxhdpi': 4,
};

/// Perbandingan dari Figma "Ikon app": huruf S 74,286 di kotak 160.
const double _letterRatio = 74.286 / 160;

/// Logo "S" hitam di kotak oranye. [radius] null = tanpa kotak (hanya
/// huruf, untuk lapisan depan ikon adaptif).
Widget _mark({required double size, double? radius, double? letterBox}) {
  final letterSize = (letterBox ?? size) * _letterRatio;
  final letter = Text(
    'S',
    textAlign: TextAlign.center,
    style: AppText.labelLarge.copyWith(
      fontSize: letterSize,
      height: 1,
      letterSpacing: 0,
      color: AppColors.onAccent,
    ),
  );
  return SizedBox(
    width: size,
    height: size,
    child: radius == null
        ? Center(child: letter)
        : DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.brandingOrange,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Center(child: letter),
          ),
  );
}

/// Glow splash (66:1979): lingkaran 360, gradasi oranye ke hitam, 35%.
Widget _glow() => Opacity(
  opacity: 0.35,
  child: Container(
    width: 360,
    height: 360,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [AppColors.brandingOrange, AppColors.primary],
      ),
    ),
  ),
);

Future<void> _save(
  WidgetTester tester,
  String path,
  Size size,
  Widget child, {
  required double ratio,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: key,
          child: SizedBox.fromSize(size: size, child: child),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path)..createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  testWidgets('ikon app dan splash Android', (tester) async {
    // Pastikan Geist Mono benar-benar dipakai (huruf monospace: lebar sama).
    double width(String text) => (TextPainter(
      text: TextSpan(text: text, style: AppText.labelLarge),
      textDirection: TextDirection.ltr,
    )..layout()).width;
    expect(width('iiii'), moreOrLessEquals(width('MMMM')));

    tester.view
      ..physicalSize = const Size(2000, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final MapEntry(key: dpi, value: ratio) in _densities.entries) {
      // Ikon lama (sebelum Android 8): kotak 48 dp sudut 12 (varian 48 px).
      await _save(
        tester,
        '$_res/mipmap-$dpi/ic_launcher.png',
        const Size.square(48),
        _mark(size: 48, radius: 12),
        ratio: ratio,
      );
      // Lapisan depan ikon adaptif: kanvas 108 dp, bagian terlihat 72 dp.
      // Juga dipakai sebagai ikon bertema Android 13 (satu warna).
      await _save(
        tester,
        '$_res/mipmap-$dpi/ic_launcher_foreground.png',
        const Size.square(108),
        _mark(size: 108, letterBox: 72),
        ratio: ratio,
      );
      // Splash sebelum Android 12: glow 360 dan logo 112 sudut 32.
      await _save(
        tester,
        '$_res/drawable-$dpi/splash_logo.png',
        const Size.square(360),
        // Latar hitam sama dengan latar splash, supaya tepi glow mulus.
        ColoredBox(
          color: AppColors.primary,
          child: Stack(
            alignment: Alignment.center,
            children: [_glow(), _mark(size: 112, radius: 32)],
          ),
        ),
        ratio: ratio,
      );
      // Splash Android 12+: ikon 288 dp (isi harus muat lingkaran 192 dp).
      await _save(
        tester,
        '$_res/drawable-$dpi/splash_icon.png',
        const Size.square(288),
        Center(child: _mark(size: 112, radius: 32)),
        ratio: ratio,
      );
      // Teks "Super App" di bawah splash (66:1982), kanvas 200 × 80 dp.
      await _save(
        tester,
        '$_res/drawable-$dpi/splash_branding.png',
        const Size(200, 80),
        Center(
          child: Text(
            'SUPER APP',
            style: AppText.labelMedium.copyWith(color: AppColors.gray),
          ),
        ),
        ratio: ratio,
      );
    }
  });
}
