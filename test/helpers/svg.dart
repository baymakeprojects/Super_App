import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/core/ui/app_icon.dart';
import 'package:super_app/core/ui/app_illustration.dart';

/// SVG dimuat secara async dari aset. Di widget test, muat dulu semua ikon
/// dan ilustrasi ke cache flutter_svg supaya golden tidak tertangkap saat
/// gambarnya masih kosong.
Future<void> precacheAppIcons(WidgetTester tester) async {
  await tester.runAsync(() async {
    final paths = [
      for (final icon in AppIcons.values) icon.assetPath,
      for (final illustration in AppIllustrations.values)
        illustration.assetPath,
    ];
    for (final path in paths) {
      final loader = SvgAssetLoader(path);
      await svg.cache.putIfAbsent(
        loader.cacheKey(null),
        () => loader.loadBytes(null),
      );
    }
  });
}
