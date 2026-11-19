# Rilis APK lewat GitHub

Cara merilis APK Super App ke halaman [Releases](https://github.com/baymakeprojects/Super_App/releases). APK dibangun oleh GitHub Actions (`.github/workflows/rilis-apk.yml`) setiap kali tag `v*` didorong. Checklist umum rilis Android ada di [`pengujian-rilis.md`](pengujian-rilis.md).

## Cara kerja workflow

Saat tag seperti `v0.4.0` didorong ke GitHub, workflow **Rilis APK**:

1. Mengecek tag cocok dengan `version` di `pubspec.yaml` (tag `v0.4.0` ↔ `version: 0.4.0+N`).
2. Mengecek file catatan rilis `docs/catatan-rilis/v0.4.0.md` ada.
3. Mengecek keenam secret sudah diisi, dan key Supabase bukan secret key.
4. `flutter pub get`, `build_runner`, `flutter analyze`.
5. `flutter build apk --release` dengan URL dan publishable key Supabase **prod** dari Secrets.
6. Menandatangani ulang APK dengan keystore release dari Secrets (`apksigner`), lalu menghapus keystore dari runner.
7. Membuat GitHub Release `Super App v0.4.0` berisi catatan rilis, `super-app-v0.4.0.apk`, dan file `.sha256`-nya.

Golden test tidak dijalankan di GitHub karena hasil render di Linux sedikit berbeda dari Windows. Jalankan `flutter test` di laptop sebelum memberi tag.

## GitHub Secrets yang harus diisi

Buka repo di GitHub → **Settings → Secrets and variables → Actions → New repository secret**. Isi sendiri; jangan pernah menempelkan nilainya di chat, issue, atau file di repo.

| Nama secret | Isi | Dari mana |
| --- | --- | --- |
| `SUPABASE_PROD_URL` | `https://<ref-prod>.supabase.co` | Dashboard Supabase → proyek **superapp-prod** → Project Settings → API |
| `SUPABASE_PROD_PUBLISHABLE_KEY` | `sb_publishable_...` | Dashboard → superapp-prod → Project Settings → API Keys. **Bukan** secret key / service role |
| `ANDROID_KEYSTORE_BASE64` | Isi file keystore `.jks` dalam bentuk base64 | Lihat perintah di bawah |
| `ANDROID_KEYSTORE_PASSWORD` | Sandi keystore | Yang kamu buat saat membuat keystore |
| `ANDROID_KEY_ALIAS` | Alias kunci, misalnya `superapp` | Yang kamu pakai di `-alias` saat membuat keystore |
| `ANDROID_KEY_PASSWORD` | Sandi kunci (sering sama dengan sandi keystore) | Yang kamu buat saat membuat keystore |

### Membuat keystore (sekali seumur app, bagian W4-08)

Simpan keystore **di luar folder repo**, misalnya `C:\kunci\`. Perintah ini menanyakan sandi dan nama:

```powershell
keytool -genkeypair -v -keystore C:\kunci\super-app-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias superapp
```

Buat cadangan keystore dan sandinya (pengelola sandi + Google Drive pribadi). Build di laptop dan build di GitHub **harus memakai keystore yang sama**; kalau berbeda atau hilang, update tidak bisa dipasang di atas versi lama.

### Mengubah keystore jadi base64 untuk secret

Perintah ini menyalin isi base64 ke clipboard, lalu tempel sebagai nilai `ANDROID_KEYSTORE_BASE64`:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\kunci\super-app-release.jks")) | Set-Clipboard
```

## Langkah merilis versi baru

1. Pastikan semua yang mau dirilis sudah di branch `main`, dan `dart format .`, `flutter analyze`, serta `flutter test` bersih di laptop.
2. Naikkan versi di `pubspec.yaml`, misalnya dari `0.3.0+3` ke `0.4.0+4`. Angka setelah `+` (nomor build) **wajib selalu naik**; Android menolak update dengan nomor build yang sama atau lebih kecil.
3. Salin `docs/catatan-rilis/TEMPLATE.md` jadi `docs/catatan-rilis/v0.4.0.md`, lalu isi.
4. Commit kedua perubahan itu ke `main` dan dorong: `git push origin main`.
5. Buat dan dorong tag:

   ```powershell
   git tag v0.4.0
   ```

   ```powershell
   git push origin v0.4.0
   ```

6. Buka tab **Actions** di GitHub dan tunggu workflow **Rilis APK** hijau (sekitar 10–15 menit).
7. Buka **Releases**, unduh APK di HP, lalu uji pasang bersih dan uji update di atas versi sebelumnya (checklist di `pengujian-rilis.md`).

### Kalau workflow gagal

- Baca langkah yang merah di tab Actions; pesan error-nya menjelaskan apa yang kurang (tag tidak cocok, catatan rilis belum ada, secret kosong).
- Perbaiki, commit, lalu pindahkan tag ke commit baru:

  ```powershell
  git tag -d v0.4.0
  ```

  ```powershell
  git push origin :refs/tags/v0.4.0
  ```

  Setelah itu ulangi langkah 5. Kalau Release sudah sempat dibuat, hapus dulu di halaman Releases.

## Rilis pertama

Rilis pertama yang layak pakai menunggu **W4-08**:

1. Buat proyek Supabase **superapp-prod**, jalankan migrasi ke prod, aktifkan login email + kode dengan template yang sama seperti dev, dan pasang SMTP sendiri (layanan email bawaan Supabase hanya mengirim ke anggota tim proyek). Lihat `setup-supabase.md`.
2. Buat keystore release dan cadangannya.
3. Isi keenam GitHub Secrets di atas.
4. Ikuti "Langkah merilis versi baru" dengan versi pertama, misalnya `v0.4.0`.
