/// Format rupiah seperti di Figma (05 Keuangan, 17 Transaksi baru):
/// titik ribuan, tanpa desimal ("Rp1.250.000"), tanda pengurang "−"
/// (U+2212, bukan tanda hubung), dan bentuk ringkas "Rp2jt", "Rp750rb".
///
/// Nominal selalu bilangan bulat rupiah (`int`), sesuai spesifikasi data.
abstract final class AppMoneyFormat {
  /// Tanda minus tipografis, seperti "−Rp15.000" di Figma.
  static const String minus = '−';

  static const int _thousand = 1000;
  static const int _million = 1000000;
  static const int _billion = 1000000000;

  /// "Rp1.250.000"; negatif "−Rp1.250.000".
  static String rupiah(int amount) {
    final sign = amount < 0 ? minus : '';
    return '${sign}Rp${_groupThousands(amount.abs())}';
  }

  /// Nominal transaksi dengan arah uang: "+Rp1.500.000" (pemasukan),
  /// "−Rp15.000" (pengeluaran). [amount] selalu positif.
  static String signed(int amount, {required bool income}) =>
      '${income ? '+' : minus}${rupiah(amount.abs())}';

  /// Bentuk ringkas untuk ringkasan bulan: "Rp2jt", "Rp1,5jt", "Rp750rb",
  /// "Rp1,2M"; di bawah seribu tetap utuh ("Rp900"). Satu angka di
  /// belakang koma, dibulatkan ke bawah supaya tidak terlihat lebih besar.
  static String compact(int amount) {
    final sign = amount < 0 ? minus : '';
    final value = amount.abs();
    final String body;
    if (value >= _billion) {
      body = '${_oneDecimal(value, _billion)}M';
    } else if (value >= _million) {
      body = '${_oneDecimal(value, _million)}jt';
    } else if (value >= _thousand) {
      body = '${_oneDecimal(value, _thousand)}rb';
    } else {
      body = '$value';
    }
    return '${sign}Rp$body';
  }

  /// Ringkasan bulan dengan tanda: "+Rp2jt", "−Rp750rb".
  static String signedCompact(int amount, {required bool income}) =>
      '${income ? '+' : minus}${compact(amount.abs())}';

  static String _oneDecimal(int value, int unit) {
    final tenths = value * 10 ~/ unit;
    final whole = tenths ~/ 10;
    final fraction = tenths % 10;
    return fraction == 0 ? '$whole' : '$whole,$fraction';
  }

  static String _groupThousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
