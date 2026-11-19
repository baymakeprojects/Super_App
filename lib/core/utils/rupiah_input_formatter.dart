import 'package:flutter/services.dart';

import 'package:super_app/core/utils/money_format.dart';

/// Kolom nominal rupiah (17 Nominal, P07 Saldo awal): hanya angka, langsung
/// tampil "Rp15.000" saat diketik. Kosong tetap kosong.
class RupiahInputFormatter extends TextInputFormatter {
  const RupiahInputFormatter();

  /// Batas digit: 999 miliar rupiah, cukup untuk keuangan mahasiswa dan
  /// aman di bawah batas `int`.
  static const int maxDigits = 12;

  /// Nilai rupiah dari teks kolom ("Rp15.000" → 15000). Kosong = 0.
  static int parse(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? 0 : int.parse(digits);
  }

  /// Teks kolom untuk [amount]; 0 = kosong.
  static String format(int amount) =>
      amount <= 0 ? '' : AppMoneyFormat.rupiah(amount);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    // Hapus nol di depan ("007" → "7").
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.length > maxDigits) return oldValue;
    final text = digits.isEmpty ? '' : format(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
