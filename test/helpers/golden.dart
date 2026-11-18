import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';

import 'svg.dart';

/// Kunci kotak yang difoto oleh golden.
const goldenKey = Key('golden');

/// Render [child] di kanvas hitam berukuran [size] (piksel = titik Figma),
/// di dalam MaterialApp dengan [AppTheme.dark], ikon sudah dimuat.
Future<void> pumpGolden(
  WidgetTester tester, {
  required Size size,
  required Widget child,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await precacheAppIcons(tester);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // Material transparan menggantikan Scaffold layar asli; tanpa ini
      // Flutter memberi teks garis bawah kuning sebagai peringatan.
      home: RepaintBoundary(
        key: goldenKey,
        child: Material(
          type: MaterialType.transparency,
          child: ColoredBox(
            color: AppColors.primary,
            // Isi memakai ukuran alaminya (seperti auto-layout Figma); selisih
            // pecahan piksel lebar teks tidak dianggap luapan, cukup terpotong.
            child: UnconstrainedBox(
              alignment: Alignment.topLeft,
              clipBehavior: Clip.hardEdge,
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Bungkus satu komponen di MaterialApp untuk tes perilaku.
Widget wrapForTest(Widget child) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(body: Center(child: child)),
);
