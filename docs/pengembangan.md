# Panduan pengembangan

Cara menjalankan Super App dari kode. Penjelasan app untuk pengunjung ada di [README](../README.md); rilis APK di [`rilis.md`](rilis.md).

## Struktur kode

`lib/features/<fitur>/{presentation,application,data}`. Layar tidak pernah memanggil Supabase langsung, selalu lewat repository. Rencana lengkap: [`prd.md`](prd.md) dan [`spesifikasi-teknis.md`](spesifikasi-teknis.md).

App hanya memegang **publishable key** Supabase. Kunci lain (service role, SMTP) dan keystore tidak pernah masuk app atau Git.

## Prasyarat

| Alat | Versi / catatan |
| --- | --- |
| Flutter SDK | 3.50 stable (Dart 3.14), dipasang di `C:\dev\flutter`; cek dengan `flutter doctor` |
| Android Studio | Untuk Android SDK dan emulator |
| VS Code | Ekstensi Flutter dan Dart |
| Git + akun GitHub | Repo [baymakeprojects/Super_App](https://github.com/baymakeprojects/Super_App) |
| Node.js | Untuk Supabase CLI lewat `npx supabase` |
| Akun Supabase | Proyek `superapp-dev` (paket gratis) |
| Claude Code | Dengan plugin Figma (lihat `START-HERE.md`) |

## Langkah pertama kali

1. **Ambil kode:** `git clone https://github.com/baymakeprojects/Super_App.git super_app` lalu `cd super_app`. Simpan di path tanpa spasi (misalnya `C:\dev\super_app`) supaya build native tidak bermasalah.
2. **Pasang paket:** `flutter pub get`.
3. **Buat kode turunan** (drift, freezed, json): `dart run build_runner build --delete-conflicting-outputs`.
4. **Siapkan Supabase dev:**
   - Buat proyek `superapp-dev` di dashboard Supabase.
   - Aktifkan login email dengan kode 6 digit dan ubah template emailnya (lihat [`setup-supabase.md`](setup-supabase.md) bagian 3).
   - Hubungkan repo: `npx supabase login`, lalu `npx supabase link --project-ref <ref-proyek>`.
   - Jalankan migrasi: `npx supabase db push`.
5. **Isi kunci lokal:** buat file `env/dev.json` (folder `env/` tidak masuk Git) dengan isi seperti ini, lalu ganti nilainya dengan URL dan publishable key dari Dashboard → Project Settings → API Keys:

   ```json
   {
     "SUPABASE_URL": "https://<ref-proyek>.supabase.co",
     "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_..."
   }
   ```

6. **Jalankan app** di HP (USB debugging aktif) atau emulator:

   ```powershell
   flutter run --dart-define-from-file=env/dev.json
   ```

   Tanpa file env (`flutter run` biasa), login dan sinkron mati, dan build debug langsung membuka Beranda dengan akun sementara `dev-lokal`.

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
| Build APK release di laptop | `flutter build apk --release --dart-define-from-file=env/prod.json` |

## Yang tidak boleh masuk Git

`env/`, `*.jks`, `*.keystore`, `android/key.properties`, `.dart_tool/`, `build/` (sudah ada di `.gitignore`).

Keystore release dan sandinya disimpan di luar repo dengan cadangan. Kalau hilang, update app tidak bisa dipasang di atas versi lama. Untuk build lewat GitHub Actions, keystore disimpan sebagai GitHub Secret (lihat [`rilis.md`](rilis.md)).

## Masalah yang sering muncul

| Gejala | Penyebab biasa | Solusi |
| --- | --- | --- |
| Kode verifikasi tidak masuk email | Layanan email bawaan Supabase hanya mengirim ke anggota tim proyek dan sangat dibatasi | Masuk dengan email akun Supabase kamu, atau pasang SMTP sendiri (lihat `setup-supabase.md`) |
| Email berisi tautan, bukan kode | Template email belum memakai `{{ .Token }}` | Ubah template *Confirm signup* dan *Magic Link* sesuai `setup-supabase.md` |
| App tidak bisa terhubung ke Supabase | Proyek dev dijeda setelah 7 hari tidak aktif | Buka dashboard Supabase dan lanjutkan proyeknya |
| Error tabel atau kolom tidak ditemukan | Migrasi belum dijalankan atau kode turunan basi | `npx supabase db push`, lalu `build_runner build` |
| Golden test gagal setelah mengubah komponen | Tampilan berubah | Cek dengan Figma dulu; kalau memang disengaja, jalankan `--update-goldens` |
| Font tampil berbeda | Font belum terdaftar di `pubspec.yaml` | Daftarkan Doto, Geist, dan Geist Mono di bagian `fonts` |
| HP menolak memasang APK baru di atas versi lama | APK ditandatangani dengan kunci berbeda | Pakai APK dari Releases, atau hapus versi lama dulu (data lokal yang belum tersinkron ikut hilang) |
