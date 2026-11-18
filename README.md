# Super App

App Flutter pribadi untuk kuliah, tugas, dan keuangan. Android dulu, Windows di Tahap 2. Backend Supabase, database lokal drift, offline-first.

Desain: [Figma Super App](https://www.figma.com/design/kK09B05WOCxXSf5dvukX41) · Rencana: folder `docs/`.

## Prasyarat

| Alat | Versi / catatan |
| --- | --- |
| Flutter SDK | 3.47 stable (Dart 3.13); cek dengan `flutter doctor` |
| Android Studio | Untuk Android SDK dan emulator |
| VS Code | Ekstensi Flutter dan Dart |
| Git + akun GitHub | Repo pribadi |
| Node.js | Untuk Supabase CLI lewat `npx supabase` |
| Akun Supabase | Proyek `superapp-dev` (paket gratis) |
| Google Cloud Console | OAuth client untuk login Google |
| Claude Code | Dengan plugin Figma (lihat `START-HERE.md`) |

## Langkah pertama kali

1. **Ambil kode:** `git clone <url-repo>` lalu `cd super_app`.
2. **Pasang paket:** `flutter pub get`.
3. **Buat kode turunan** (drift, freezed, json): `dart run build_runner build --delete-conflicting-outputs`.
4. **Siapkan Supabase dev:**
   - Buat proyek `superapp-dev` di dashboard Supabase.
   - Aktifkan provider Google di Authentication. Buat dua OAuth client di Google Cloud: tipe Web (Client ID-nya dipakai Supabase dan app) dan tipe Android (isi package name dan SHA-1 keystore debug dari `cd android && ./gradlew signingReport`).
   - Hubungkan repo: `npx supabase login`, lalu `npx supabase link --project-ref <ref-proyek>`.
   - Jalankan migrasi: `npx supabase db push`.
5. **Isi kunci lokal:** salin `env/dev.example.json` jadi `env/dev.json` lalu isi (folder `env/` tidak masuk Git).
6. **Jalankan app** di HP (USB debugging aktif) atau emulator: `flutter run --dart-define-from-file=env/dev.json`.

## Perintah sehari-hari

| Keperluan | Perintah |
| --- | --- |
| Jalankan app (dev) | `flutter run --dart-define-from-file=env/dev.json` |
| Format kode | `dart format .` |
| Cek kode | `flutter analyze` |
| Semua tes | `flutter test` |
| Perbarui golden test setelah perubahan desain yang disengaja | `flutter test --update-goldens` |
| Tes integrasi di HP | `flutter test integration_test` |
| Buat kode turunan saat tabel atau model berubah | `dart run build_runner build --delete-conflicting-outputs` |
| Migrasi database baru | `npx supabase migration new <nama>`, isi SQL-nya, lalu `npx supabase db push` |
| Build APK release | `flutter build apk --release --dart-define-from-file=env/prod.json` |

## Yang tidak boleh masuk Git

`env/`, `*.jks`, `*.keystore`, `android/key.properties`, `.dart_tool/`, `build/` (sudah ada di `.gitignore`).

Keystore release dan sandinya disimpan di luar repo dengan cadangan (misalnya pengelola sandi + Google Drive pribadi). Kalau hilang, update app tidak bisa dipasang di atas versi lama.

## Masalah yang sering muncul

| Gejala | Penyebab biasa | Solusi |
| --- | --- | --- |
| Login Google gagal dengan error 10 atau developer error | SHA-1 di OAuth client Android tidak cocok | Ambil ulang SHA-1 dengan `signingReport`, perbarui di Google Cloud |
| App tidak bisa terhubung ke Supabase | Proyek dev dijeda setelah 7 hari tidak aktif | Buka dashboard Supabase dan lanjutkan proyeknya |
| Error tabel atau kolom tidak ditemukan | Migrasi belum dijalankan atau kode turunan basi | `npx supabase db push`, lalu `build_runner build` |
| Golden test gagal setelah mengubah komponen | Tampilan berubah | Cek dengan Figma dulu; kalau memang disengaja, jalankan `--update-goldens` |
| Font tampil berbeda | Font belum terdaftar di `pubspec.yaml` | Daftarkan Doto, Geist, dan Geist Mono di bagian `fonts` |
