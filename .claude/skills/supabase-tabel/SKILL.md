---
name: supabase-tabel
description: Tambah atau ubah tabel data Super App dari ujung ke ujung — migrasi SQL Supabase dengan RLS, tabel drift lokal, antrean sinkron, repository, dan tesnya. Pakai saat membuat atau mengubah tabel seperti tasks, courses, wallets, transactions.
argument-hint: "[nama tabel]"
---

# Tabel baru atau berubah

Tabel: **$ARGUMENTS**

Acuan: `docs/spesifikasi-teknis.md` (Model data, Keamanan data, Sinkron offline).

## Aturan wajib
- Kolom standar di setiap tabel: `id uuid primary key` (dibuat di HP), `user_id uuid not null references auth.users`, `created_at`, `updated_at timestamptz not null default now()`, `deleted_at timestamptz` (soft delete).
- Nominal uang `bigint` rupiah. Saldo tidak disimpan.
- Row Level Security wajib, aturan "hanya milik sendiri" untuk select/insert/update/delete.
- Perubahan database **hanya** lewat file di `supabase/migrations/`. Jangan klik di dashboard, jangan ubah migrasi yang sudah di-push — buat migrasi baru.
- Jangan pernah memakai kunci service role di app atau menulisnya ke repo.

## Langkah
1. **Migrasi Supabase**
   - `npx supabase migration new <nama>`.
   - Tulis `create table`, index untuk `user_id` dan `updated_at`, trigger yang mengisi `updated_at` saat update, `alter table … enable row level security`, dan policy:
     ```sql
     create policy "hanya milik sendiri" on <tabel>
       for all using (user_id = auth.uid()) with check (user_id = auth.uid());
     ```
   - Jangan jalankan `db push` sendiri. Tunjukkan SQL ke Bayu dan minta dia menjalankan `npx supabase db push` ke proyek **dev**.
2. **Tabel drift** di `lib/core/db/tables/` dengan kolom yang sama (nama Dart camelCase, nama SQL snake_case). Naikkan `schemaVersion` dan tulis migrasi drift kalau database lokal sudah pernah dibuat.
3. **Kode turunan:** `dart run build_runner build --delete-conflicting-outputs`.
4. **Repository** di `lib/features/<fitur>/data/`:
   - Baca dari drift (stream untuk layar), selalu menyaring `deleted_at is null`.
   - Tambah/ubah/hapus: tulis ke drift **dan** ke `sync_queue` dalam satu transaksi drift. Hapus = isi `deleted_at`.
   - Urungkan = kembalikan nilai sebelumnya lewat operasi biasa (juga masuk antrean).
5. **Sinkron:** daftarkan tabel di mesin sinkron (`lib/core/sync/`) supaya ikut dikirim dan ditarik.
6. **Tes**
   - Unit test repository dengan drift in-memory: tambah, ubah, hapus, urungkan, dan isi `sync_queue`.
   - Uji RLS (tulis langkahnya untuk Bayu kalau tidak bisa dijalankan dari sini): akun A tidak bisa membaca atau mengubah baris akun B di proyek dev.
7. `dart format .`, `flutter analyze`, `flutter test`.
