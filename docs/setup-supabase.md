# Setup Supabase dan login Google

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

## 2. Uji RLS dua akun

Buka Dashboard → **superapp-dev** → SQL Editor, tempel seluruh isi `supabase/tests/rls_dua_akun.sql`, lalu Run. Hasil yang benar: satu baris berbunyi **LULUS**. Semua akun dan data uji dibatalkan otomatis (rollback).

## 3. Login Google

### Google Cloud Console

1. Buat proyek Google Cloud (misalnya `super-app`).
2. **OAuth consent screen**: tipe External, status Testing, tambahkan email Google kamu sebagai test user.
3. **Credentials → Create OAuth client ID → Web application**
   - Authorized redirect URI: `https://nyzktdlyfuqjxumlicgf.supabase.co/auth/v1/callback`
   - Catat **Client ID** dan **Client secret** (secret jangan masuk Git).
4. **Credentials → Create OAuth client ID → Android**
   - Package name: `com.bayu.super_app`
   - SHA-1: jalankan perintah di bawah, lalu salin SHA1 dari varian `debug`.

```powershell
cd android; .\gradlew signingReport
```

### Supabase

Dashboard → **superapp-dev** → Authentication → Sign In / Providers → **Google**:

- Aktifkan.
- Isi **Client ID** dan **Client secret** dari client *Web application*.
- Simpan.

### File env

Salin `env/dev.example.json` jadi `env/dev.json`, lalu isi URL dev di atas, publishable key (Dashboard → Project Settings → API Keys), dan Client ID *Web application* kalau ada kuncinya di contoh. `env/dev.json` sudah masuk `.gitignore`.

Kode login di app (layar 01, google_sign_in + Supabase Auth) dibuat di tugas layar login; langkah di atas cukup menyiapkan sisi Supabase dan Google.
