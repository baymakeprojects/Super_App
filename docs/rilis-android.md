# Rilis Android (W4-08)

Langkah dari kode di `main` sampai APK rilis terpasang di HP Bayu. Bagian yang menyangkut rahasia (sandi keystore, kunci Supabase, `env/`) dikerjakan Bayu sendiri; Claude Code tidak membaca atau menulisnya.

## 1. Proyek Supabase prod

Status 20 Nov 2026: **sudah dibuat** lewat Claude Code (biaya $0/bulan, disetujui Bayu) setelah Bayu menghapus `bayproject` (paket gratis membatasi 2 proyek aktif).

| Nama | Ref | Region | URL API |
| --- | --- | --- | --- |
| `superapp-prod` | `omogcmwhzsqotsgvbfwu` | ap-southeast-1 (Singapura) | `https://omogcmwhzsqotsgvbfwu.supabase.co` |

Sudah: migrasi `mvp_tables` diterapkan, uji RLS dua akun **LULUS**, pemeriksaan keamanan Supabase (advisor) tanpa temuan. Belum (bagian Bayu): langkah 3–5 di bawah.

Setelah proyek prod ada:

1. Migrasi sudah diterapkan lewat Supabase MCP. Untuk migrasi berikutnya lewat CLI, sambungkan dulu (reset password database prod di Dashboard → Project Settings → Database kalau diminta):

```powershell
npx supabase link --project-ref omogcmwhzsqotsgvbfwu
```

Kalau `db push` menganggap migrasi pertama belum ada (nomor versinya beda karena diterapkan lewat MCP), tandai sebagai sudah diterapkan:

```powershell
npx supabase migration repair --status applied 20261118234355
```

2. Uji RLS dua akun sudah LULUS di prod (20 Nov 2026). Ulangi setiap ada tabel baru.
3. Atur login email + kode persis seperti dev (`docs/setup-supabase.md` §3): provider Email, OTP 6 digit, 600 detik, template berisi `{{ .Token }}`.
4. Pasang SMTP sendiri (misalnya Resend atau Brevo) di Authentication → Emails → SMTP Settings. Layanan email bawaan Supabase hanya mengirim ke anggota tim dan sangat terbatas.
5. Buat `env/prod.json` (sudah di `.gitignore`):

```json
{
  "SUPABASE_URL": "https://omogcmwhzsqotsgvbfwu.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_..."
}
```

Publishable key ada di Dashboard → Project Settings → API Keys. Kunci service role tidak pernah dipakai di app.

## 2. Keystore rilis

APK rilis harus ditandatangani dengan kunci milik Bayu sendiri. Kalau keystore atau sandinya hilang, versi baru tidak bisa dipasang di atas versi lama, jadi **buat cadangan** (misalnya di password manager dan penyimpanan cloud pribadi).

Cara paling mudah: jalankan skrip ini sekali dari folder proyek. Skrip menanyakan sandi di terminal, membuat keystore di `%USERPROFILE%\keystore\super_app.jks`, lalu menulis `android/key.properties`. Sandi tidak dikirim ke mana pun.

```powershell
powershell -ExecutionPolicy Bypass -File tool\buat-keystore.ps1
```

Atau secara manual:

1. Buat keystore di luar folder proyek (jalankan sekali). `keytool` ikut terpasang bersama Android Studio (folder `jbr\bin`):

```powershell
keytool -genkey -v -keystore $env:USERPROFILE\keystore\super_app.jks -keyalg RSA -keysize 2048 -validity 10000 -alias super_app
```

2. Buat file `android/key.properties` (sudah di `.gitignore`, jangan di-commit):

```properties
storePassword=<sandi keystore>
keyPassword=<sandi kunci>
keyAlias=super_app
storeFile=C:/Users/<nama>/keystore/super_app.jks
```

`android/app/build.gradle.kts` membaca file ini. Tanpa file itu, build release memakai kunci debug (hanya untuk mencoba, jangan dibagikan).

## 3. Build dan pasang

1. Naikkan versi di `pubspec.yaml` setiap rilis: `0.1.0+1` → `0.1.1+2` (angka setelah `+` selalu naik).
2. Build:

```powershell
flutter build apk --release --dart-define-from-file=env/prod.json
```

   APK ini berisi kode untuk semua jenis prosesor (sekitar 62 MB). Untuk HP sendiri cukup versi per prosesor, sekitar sepertiganya; hampir semua HP Android sekarang memakai `app-arm64-v8a-release.apk`:

```powershell
flutter build apk --release --split-per-abi --dart-define-from-file=env/prod.json
```

3. Hasilnya `build\app\outputs\flutter-apk\app-release.apk` (atau `app-arm64-v8a-release.apk` dengan `--split-per-abi`). Pasang lewat USB:

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

atau salin APK ke HP lalu buka (izinkan "pasang dari sumber tidak dikenal" untuk aplikasi file).

4. Uji pasang bersih (hapus app debug dulu: kunci tanda tangan berbeda) dan uji update (pasang versi berikutnya di atasnya).
5. Coba alur utama di HP: Intro → masuk dengan email dan kode → Setup awal → tambah tugas, jadwal, transaksi → tutup app → buka lagi (sidik jari) → matikan internet → ubah sesuatu → nyalakan lagi → cek data di Supabase prod.

## 4. Izin app

Hanya `INTERNET` (login dan sinkron) dan izin sidik jari dari paket local_auth. Tidak ada izin lokasi, kamera, atau penyimpanan.
