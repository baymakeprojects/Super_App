# Setup Supabase dan login email

Langkah yang dikerjakan Bayu sendiri di dashboard. Claude Code tidak boleh membaca atau menulis `env/`, kunci service role, atau keystore.

## Proyek

| Lingkungan | Nama | Ref | Region |
| --- | --- | --- | --- |
| Dev | `superapp-dev` | `nyzktdlyfuqjxumlicgf` | ap-southeast-1 (Singapura) |
| Prod | `superapp-prod` | belum dibuat | — |

URL API dev: `https://nyzktdlyfuqjxumlicgf.supabase.co`

## 1. Password database dan sambungan CLI

Proyek dev dibuat lewat Claude Code, jadi password database-nya belum kamu ketahui.

1. Dashboard → **superapp-dev** → Project Settings → Database → **Reset database password**. Simpan password baru di password manager.
2. Di terminal, dari folder proyek:

```powershell
npx supabase login
```

```powershell
npx supabase link --project-ref nyzktdlyfuqjxumlicgf
```

3. Terapkan migrasi ke dev (selalu dev dulu, prod belakangan):

```powershell
npx supabase db push
```

Status dev: migrasi `20261118234355_mvp_tables` sudah diterapkan oleh Claude Code lewat Supabase MCP (19 Nov 2026), dan uji RLS dua akun sudah LULUS. `db push` berikutnya cukup mengirim migrasi baru.

## 2. Uji RLS dua akun

Buka Dashboard → **superapp-dev** → SQL Editor, tempel seluruh isi `supabase/tests/rls_dua_akun.sql`, lalu Run. Hasil yang benar: satu baris berbunyi **LULUS**. Semua akun dan data uji dibatalkan otomatis (rollback).

## 3. Login email dengan kode verifikasi

Login memakai email + kode 6 digit (tanpa password, tanpa Google). Keputusan Bayu, 19 Nov 2026. Alurnya: app mengirim email → Supabase mengirim kode → pengguna mengetik kode di app.

### Provider Email

Dashboard → **superapp-dev** → Authentication → Sign In / Providers → **Email**:

- **Enable Email provider**: aktif.
- **Confirm email**: aktif.
- **Email OTP Length**: 6.
- **Email OTP Expiration**: 600 detik (10 menit) sudah cukup.
- Simpan.

### Template email berisi kode

Secara bawaan Supabase mengirim **tautan**. Supaya yang dikirim **kode**, template harus memakai `{{ .Token }}`.

Dashboard → Authentication → **Emails** → Templates. Ubah dua template ini (akun baru memakai *Confirm signup*, akun lama memakai *Magic Link*):

- **Confirm signup**: subjek `Kode masuk Super App`, isi:

```html
<h2>Kode masuk Super App</h2>
<p>Masukkan kode ini di app:</p>
<p style="font-size: 28px; letter-spacing: 6px"><strong>{{ .Token }}</strong></p>
<p>Kode berlaku 10 menit. Abaikan email ini kalau kamu tidak sedang masuk.</p>
```

- **Magic Link**: subjek dan isi yang sama.

### Batas pengiriman email

- Layanan email bawaan Supabase hanya untuk mencoba: jumlah email per jam sangat sedikit, dan email hanya terkirim ke alamat anggota tim proyek (akun Supabase kamu sendiri).
- Untuk dev, masuk dengan email akun Supabase kamu.
- Sebelum rilis (atau sebelum teman ikut mencoba), pasang SMTP sendiri: Authentication → Emails → **SMTP Settings** (misalnya Resend atau Brevo, keduanya punya paket gratis). Kunci SMTP hanya di dashboard, jangan masuk Git.

### File env

Salin `env/dev.example.json` jadi `env/dev.json`, lalu isi URL dev di atas dan publishable key (Dashboard → Project Settings → API Keys). `env/dev.json` sudah masuk `.gitignore`.

App membaca dua nama ini (W1-10, `lib/core/config/app_config.dart`). Pastikan nama kunci di file env sama persis:

```json
{
  "SUPABASE_URL": "https://nyzktdlyfuqjxumlicgf.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_..."
}
```

Nama lama `SUPABASE_ANON_KEY` juga diterima. Tanpa file env (`flutter run` biasa), login dan sinkron mati dan build debug langsung membuka Beranda dengan akun sementara `dev-lokal`.

### Di kode app (W1-10, sudah dibuat)

Layar 00e dan 00f memanggil Supabase lewat `SupabaseAuthRepository` (`lib/features/auth/data/auth_repository.dart`). Sesi login disimpan terenkripsi di HP (flutter_secure_storage). Saat login pertama, data yang dicatat dengan akun `dev-lokal` dipindahkan ke akun asli lalu ikut sinkron. Panggilannya:

```dart
// 1. Kirim kode ke email (akun baru dibuat otomatis).
await supabase.auth.signInWithOtp(email: email);

// 2. Cocokkan kode yang diketik pengguna.
await supabase.auth.verifyOTP(type: OtpType.email, email: email, token: kode);
```

Profil dibuat otomatis oleh trigger database saat akun pertama kali dibuat. Untuk akun email, `name` awalnya kosong (lihat F-14).
