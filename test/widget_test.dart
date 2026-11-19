import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/app.dart';
import 'package:super_app/core/theme/theme.dart';

void main() {
  testWidgets('SuperApp bisa dibangun dan memakai mode gelap', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SuperApp()));
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsWidgets);

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(Theme.of(context).scaffoldBackgroundColor, AppColors.primary);
  });
}
