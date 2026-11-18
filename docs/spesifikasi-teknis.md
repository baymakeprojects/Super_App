# Spesifikasi teknis

Bahasa, library, arsitektur, dan struktur data untuk MVP. Versi dicek 7 Nov 2026; jalankan `flutter pub add` saat mulai supaya dapat versi terbaru.

## Bahasa & alat

| Bagian | Bahasa / alat | Catatan |
| --- | --- | --- |
| App Android & desktop | Dart 3.13 + Flutter 3.47 (stable) | Satu kode untuk Android sekarang dan Windows di Tahap 2 |
| Database di HP | SQLite lewat drift | Sumber data utama; UI selalu membaca dari sini |
| Backend | Supabase: Postgres, Auth, Storage, Realtime | Paket gratis memberi 2 proyek aktif |
| Struktur & keamanan data | SQL (migrasi + Row Level Security) | Ditulis di `supabase/migrations`, bukan diklik di dashboard |
| Fungsi server | TypeScript di Supabase Edge Functions | Belum dipakai di MVP |
| Editor | VS Code + ekstensi Flutter & Dart; Android Studio untuk SDK dan emulator | |
| Versi kode | Git + GitHub | Satu fitur per branch |

## Library

| Kebutuhan | Paket | Tahap |
| --- | --- | --- |
| State | flutter_riverpod | MVP |
| Navigasi | go_router | MVP |
| Database lokal | drift, drift_flutter | MVP |
| Supabase | supabase_flutter | MVP |
| Login Google | google_sign_in (lewat Supabase Auth) | MVP |
| Sidik jari | local_auth | MVP |
| Simpan PIN dan sesi | flutter_secure_storage | MVP |
| Format Rp dan tanggal | intl (locale id_ID) | MVP |
| Cek koneksi | connectivity_plus | MVP |
| Model data | freezed, json_serializable | MVP |
| Ikon SVG dari Figma | flutter_svg | MVP |
| Notifikasi | flutter_local_notifications | Tahap 2 |
| Scan dokumen | google_mlkit_document_scanner, file_picker | Tahap 2 |
| Grafik | fl_chart | Tahap 3 |

Font Doto, Geist, dan Geist Mono dipasang sebagai aset di `assets/fonts`, bukan diunduh saat app jalan, supaya tetap tampil saat offline.

## Arsitektur

Setiap fitur punya tiga lapis:

- **presentation** — layar dan widget; hanya memakai komponen dari `core/ui` dan token dari `core/theme`.
- **application** — provider Riverpod yang memegang state dan aksi.
- **data** — repository yang membaca dan menulis drift, lalu mencatat perubahan ke antrean sinkron.

Layar tidak pernah memanggil Supabase langsung; semua lewat repository.

```
lib/
  main.dart
  app/              # MaterialApp, go_router, tema
  core/
    theme/          # token dari Figma: colors, typography, spacing, radius
    ui/             # widget dari halaman Components Figma
    db/             # database drift dan tabelnya
    sync/           # antrean dan mesin sinkron
    config/         # konfigurasi app
    utils/          # format Rp, tanggal, jam
  features/
    auth/  beranda/  tugas/  kuliah/  keuangan/  lainnya/  pengaturan/
      presentation/  application/  data/
assets/
  fonts/  icons/
supabase/
  migrations/  functions/
test/  integration_test/
```

## Model data (MVP)

Semua tabel punya `id` (uuid, dibuat di HP), `user_id`, `created_at`, `updated_at`, dan `deleted_at`. Hapus berarti mengisi `deleted_at`, supaya perangkat lain ikut tahu.

| Tabel | Kolom utama |
| --- | --- |
| profiles | nama, avatar_url |
| semesters | nama, mulai, selesai, aktif |
| courses | semester_id, nama, kode, sks, dosen, ruang, warna |
| class_sessions | course_id, hari (1–7), jam_mulai, jam_selesai, ruang |
| tasks | course_id (opsional), judul, catatan, deadline, prioritas, status, selesai_at |
| subtasks | task_id, judul, selesai, urutan |
| wallets | nama, jenis (tunai, bank, e-wallet), saldo_awal |
| categories | nama, jenis (masuk, keluar), ikon |
| transactions | wallet_id, category_id, jenis, nominal, catatan, tanggal |
| sync_queue (hanya di HP) | nama_tabel, id_baris, operasi, dibuat |

Nominal disimpan sebagai bilangan bulat rupiah (`bigint`), tanpa desimal. Saldo dompet tidak disimpan; dihitung dari saldo awal ditambah semua transaksinya.

## Keamanan data

Setiap tabel di Supabase wajib memakai Row Level Security dengan aturan yang sama:

```sql
alter table tasks enable row level security;

create policy "hanya milik sendiri" on tasks
  for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
```

App hanya memegang kunci publik Supabase. Kunci service role tidak pernah masuk ke app atau ke Git.

## Sinkron offline

1. Setiap tambah, ubah, atau hapus ditulis ke drift dan ke `sync_queue` dalam satu transaksi.
2. Saat online, antrean dikirim berurutan ke Supabase (upsert), lalu baris yang terkirim dihapus dari antrean.
3. App menarik perubahan dari Supabase yang `updated_at`-nya lebih baru dari tarikan terakhir.
4. Kalau satu baris diubah di dua tempat, `updated_at` terbaru yang dipakai. Pilihan dua versi untuk catatan (E6) menyusul di Tahap 2.

Kalau membuat sinkron sendiri terasa terlalu berat, PowerSync atau paket syncable (drift + Supabase) bisa dipakai sebagai gantinya — tanya Bayu dulu sebelum menambah paket.

## Lingkungan

- Dua proyek Supabase: `superapp-dev` untuk mencoba dan `superapp-prod` untuk data asli.
- URL dan kunci publik dibaca dari `env/dev.json` atau `env/prod.json` lewat `--dart-define-from-file`; folder `env/` masuk `.gitignore`.
- Perubahan database selalu lewat file migrasi Supabase CLI, diuji di dev dulu.
