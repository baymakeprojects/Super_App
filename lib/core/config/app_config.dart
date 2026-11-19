/// Alamat dan kunci publik Supabase, dibaca saat build dari
/// `--dart-define-from-file=env/dev.json` (atau `env/prod.json`).
///
/// Isi file env (lihat `docs/setup-supabase.md`):
/// `{"SUPABASE_URL": "...", "SUPABASE_PUBLISHABLE_KEY": "..."}`.
/// Hanya publishable key yang boleh ada di app; kunci service role tidak
/// pernah masuk app atau Git.
abstract final class AppConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Publishable key. Nama lama `SUPABASE_ANON_KEY` juga diterima.
  static const String supabaseKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  /// `false` kalau app dijalankan tanpa file env: login dan sinkron mati,
  /// build debug memakai akun sementara `dev-lokal`.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
