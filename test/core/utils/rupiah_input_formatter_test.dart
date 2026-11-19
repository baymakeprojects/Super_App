import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/core/utils/rupiah_input_formatter.dart';

TextEditingValue _type(String text) => const RupiahInputFormatter()
    .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text));

void main() {
  test('hanya angka, langsung berformat rupiah', () {
    expect(_type('15000').text, 'Rp15.000');
    expect(_type('Rp15.0005').text, 'Rp150.005');
    expect(_type('abc').text, '');
    expect(_type('007').text, 'Rp7');
    expect(_type('15000').selection.baseOffset, 'Rp15.000'.length);
  });

  test('parse dan format', () {
    expect(RupiahInputFormatter.parse('Rp1.250.000'), 1250000);
    expect(RupiahInputFormatter.parse(''), 0);
    expect(RupiahInputFormatter.format(0), '');
    expect(RupiahInputFormatter.format(500000), 'Rp500.000');
  });

  test('lebih dari 12 digit ditolak', () {
    const old = TextEditingValue(text: 'Rp999.999.999.999');
    final result = const RupiahInputFormatter().formatEditUpdate(
      old,
      const TextEditingValue(text: 'Rp999.999.999.9999'),
    );
    expect(result, old);
  });
}
