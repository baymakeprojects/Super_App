import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/core/utils/money_format.dart';

void main() {
  test('rupiah penuh dengan titik ribuan (05, 17)', () {
    expect(AppMoneyFormat.rupiah(0), 'Rp0');
    expect(AppMoneyFormat.rupiah(900), 'Rp900');
    expect(AppMoneyFormat.rupiah(15000), 'Rp15.000');
    expect(AppMoneyFormat.rupiah(1250000), 'Rp1.250.000');
    expect(AppMoneyFormat.rupiah(-150000), '−Rp150.000');
  });

  test('nominal transaksi bertanda (Transaksi terakhir di 05)', () {
    expect(AppMoneyFormat.signed(15000, income: false), '−Rp15.000');
    expect(AppMoneyFormat.signed(1500000, income: true), '+Rp1.500.000');
  });

  test('bentuk ringkas ringkasan bulan (Masuk/Keluar di 05)', () {
    expect(AppMoneyFormat.signedCompact(2000000, income: true), '+Rp2jt');
    expect(AppMoneyFormat.signedCompact(750000, income: false), '−Rp750rb');
    expect(AppMoneyFormat.compact(1550000), 'Rp1,55jt');
    expect(AppMoneyFormat.compact(1250000), 'Rp1,25jt');
    expect(AppMoneyFormat.compact(1500000), 'Rp1,5jt');
    expect(AppMoneyFormat.compact(1999999), 'Rp1,99jt');
    expect(AppMoneyFormat.compact(2500), 'Rp2,5rb');
    expect(AppMoneyFormat.compact(1205000000), 'Rp1,2M');
    expect(AppMoneyFormat.compact(900), 'Rp900');
    expect(AppMoneyFormat.compact(0), 'Rp0');
  });
}
