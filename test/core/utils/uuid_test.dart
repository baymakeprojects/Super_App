import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/core/utils/uuid.dart';

void main() {
  test('UUID v4: format standar dan tidak berulang', () {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final ids = List.generate(1000, (_) => newUuidV4());

    for (final id in ids) {
      expect(id, matches(pattern));
    }
    expect(ids.toSet(), hasLength(ids.length));
  });
}
