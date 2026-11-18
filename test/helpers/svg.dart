import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/core/ui/app_icon.dart';

/// SVG dimuat secara async dari aset. Di widget test, muat dulu semua ikon
/// ke cache flutter_svg supaya golden tidak tertangkap saat ikon masih kosong.
Future<void> precacheAppIcons(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final icon in AppIcons.values) {
      final loader = SvgAssetLoader(icon.assetPath);
      await svg.cache.putIfAbsent(
        loader.cacheKey(null),
        () => loader.loadBytes(null),
      );
    }
  });
}
