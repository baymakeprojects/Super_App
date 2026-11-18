import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/app.dart';

void main() {
  testWidgets('SuperApp bisa dibangun dan memakai mode gelap', (tester) async {
    await tester.pumpWidget(const SuperApp());

    expect(find.byType(Scaffold), findsOneWidget);

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
