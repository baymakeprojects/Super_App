/// Semua path rute MVP, persis seperti tabel di `docs/navigasi.md`.
/// Jangan menambah rute di luar tabel itu.
abstract final class AppRoutes {
  static const String intro = '/intro';
  static const String masuk = '/masuk';
  static const String masukKode = '/masuk/kode';
  static const String kunci = '/kunci';
  static const String kunciPin = '/kunci/pin';
  static const String setupJadwal = '/setup/jadwal';
  static const String setupDompet = '/setup/dompet';
  static const String setupKeamanan = '/setup/keamanan';

  // Lima tab Bottom Nav, urutannya sama dengan AppBottomNav.tabs.
  static const String beranda = '/beranda';
  static const String tugas = '/tugas';
  static const String kuliah = '/kuliah';
  static const String keuangan = '/keuangan';
  static const String lainnya = '/lainnya';

  static const String tugasBaru = '/tugas/baru';
  static const String tugasCari = '/tugas/cari';
  static String tugasDetail(String id) => '/tugas/$id';
  static String tugasEdit(String id) => '/tugas/$id/edit';

  static const String kuliahJadwalBaru = '/kuliah/jadwal-baru';
  static String kuliahDetail(String id) => '/kuliah/$id';
  static String kuliahEdit(String id) => '/kuliah/$id/edit';

  static const String keuanganTransaksiBaru = '/keuangan/transaksi-baru';
  static String keuanganTransaksi(String id) => '/keuangan/transaksi/$id';

  static const String pengaturan = '/pengaturan';
  static const String pengaturanPin = '/pengaturan/pin';

  /// Hanya ada di build debug: katalog komponen `core/ui`.
  static const String katalog = '/katalog';
}
