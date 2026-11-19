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

  /// Bentuk ringkas seperti Figma: "Rp2jt", "Rp1,25jt" (02), "Rp750rb";
  /// di bawah seribu tetap utuh ("Rp900"). Paling banyak dua angka di
  /// belakang koma tanpa nol di akhir, dibulatkan ke bawah supaya tidak
  /// terlihat lebih besar.
  static String compact(int amount) {
    final sign = amount < 0 ? minus : '';
    final value = amount.abs();
    final String body;
    if (value >= _billion) {
      body = '${_twoDecimals(value, _billion)}M';
    } else if (value >= _million) {
      body = '${_twoDecimals(value, _million)}jt';
    } else if (value >= _thousand) {
      body = '${_twoDecimals(value, _thousand)}rb';
    } else {
      body = '$value';
    }
    return '${sign}Rp$body';
  }

  /// Ringkasan bulan dengan tanda: "+Rp2jt", "−Rp750rb".
  static String signedCompact(int amount, {required bool income}) =>
      '${income ? '+' : minus}${compact(amount.abs())}';

  static String _twoDecimals(int value, int unit) {
    final hundredths = value * 100 ~/ unit;
    final whole = hundredths ~/ 100;
    final fraction = (hundredths % 100).toString().padLeft(2, '0');
    final trimmed = fraction.replaceFirst(RegExp(r'0+$'), '');
    return trimmed.isEmpty ? '$whole' : '$whole,$trimmed';
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
