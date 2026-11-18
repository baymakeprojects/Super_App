import 'dart:io';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';

import '../../helpers/svg.dart';
import 'icons_sheet.dart';

Widget _frame(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  test('ada 39 ikon dan setiap ikon punya file SVG', () {
    expect(AppIcons.values, hasLength(39));

    final files = Directory('assets/icons')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.svg'))
        .length;
    expect(files, AppIcons.values.length);

    for (final icon in AppIcons.values) {
      expect(File(icon.assetPath).existsSync(), isTrue, reason: icon.name);
    }
  });

  testWidgets('semua ikon tampil 24×24', (tester) async {
    await precacheAppIcons(tester);

    for (final icon in AppIcons.values) {
      await tester.pumpWidget(_frame(Center(child: AppIcon(icon))));
      expect(
        tester.getSize(find.byType(AppIcon)),
        const Size.square(24),
        reason: icon.name,
      );
    }
  });

  testWidgets('warna dan ukuran bisa diganti', (tester) async {
    await precacheAppIcons(tester);
    await tester.pumpWidget(
      _frame(
        const Center(
          child: AppIcon(
            AppIcons.search,
            color: AppColors.brandingOrange,
            size: 32,
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(AppIcon)), const Size.square(32));
    final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(
      picture.colorFilter,
      const ColorFilter.mode(AppColors.brandingOrange, BlendMode.srcIn),
    );
  });

  testWidgets('bawaan berwarna White dan tanpa label pembaca layar', (
    tester,
  ) async {
    await precacheAppIcons(tester);
    await tester.pumpWidget(
      _frame(const Center(child: AppIcon(AppIcons.home))),
    );

    final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(
      picture.colorFilter,
      const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
    );
    expect(picture.excludeFromSemantics, isTrue);
  });

  testWidgets('golden: [01] Ikon sama dengan Figma (node 5:7)', (tester) async {
    tester.view
      ..physicalSize = IconsSheet.frameSize
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await precacheAppIcons(tester);
    await tester.pumpWidget(_frame(const RepaintBoundary(child: IconsSheet())));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(IconsSheet),
      matchesGoldenFile('goldens/app_icon_sheet.png'),
    );
  });

  testWidgets('golden: ikon bisa diwarnai dengan token', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 56)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const colors = [
      AppColors.white,
      AppColors.lightGray,
      AppColors.gray,
      AppColors.brandingOrange,
      AppColors.success,
      AppColors.warning,
      AppColors.danger,
    ];

    await precacheAppIcons(tester);
    await tester.pumpWidget(
      _frame(
        RepaintBoundary(
          key: const Key('colors'),
          child: ColoredBox(
            color: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s16),
              child: Row(
                spacing: AppSpace.s16,
                children: [
                  for (final color in colors)
                    AppIcon(AppIcons.check, color: color),
                  const ColoredBox(
                    color: AppColors.brandingOrange,
                    child: AppIcon(AppIcons.plus, color: AppColors.onAccent),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('colors')),
      matchesGoldenFile('goldens/app_icon_colors.png'),
    );
  });
}
