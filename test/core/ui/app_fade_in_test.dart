import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';

double _opacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find.descendant(
        of: find.byType(AppFadeIn),
        matching: find.byType(FadeTransition),
      ),
    )
    .opacity
    .value;

Widget _wrap(Widget child, {bool disableAnimations = false}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: child,
  ),
);

void main() {
  testWidgets('animateFirst: mulai transparan, lalu tampil penuh', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const AppFadeIn(
          duration: AppMotion.launch,
          animateFirst: true,
          child: Text('isi'),
        ),
      ),
    );
    expect(_opacity(tester), 0);
    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);
  });

  testWidgets('trigger berubah: pudar ulang tanpa membangun ulang isi', (
    tester,
  ) async {
    final key = GlobalKey();
    Widget build(int tab) => _wrap(
      AppFadeIn(
        duration: AppMotion.tab,
        trigger: tab,
        child: SizedBox(key: key),
      ),
    );

    await tester.pumpWidget(build(0));
    expect(_opacity(tester), 1);
    final element = key.currentContext;

    await tester.pumpWidget(build(1));
    expect(_opacity(tester), 0);
    await tester.pump(AppMotion.tab ~/ 2);
    expect(_opacity(tester), inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);
    expect(key.currentContext, same(element));
  });

  testWidgets('animasi dimatikan di HP: langsung tampil', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AppFadeIn(
          duration: AppMotion.launch,
          animateFirst: true,
          child: Text('isi'),
        ),
        disableAnimations: true,
      ),
    );
    expect(_opacity(tester), 1);
  });

  test('semua platform memakai transisi layar app', () {
    final builders = AppTheme.dark.pageTransitionsTheme.builders;
    expect(builders[TargetPlatform.android], isA<AppPageTransitionsBuilder>());
    expect(
      const AppPageTransitionsBuilder().transitionDuration,
      AppMotion.page,
    );
  });
}
