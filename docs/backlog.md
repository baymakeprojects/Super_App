# Backlog MVP

Empat fase di PRD, dipecah jadi tugas kecil. Tidak ada tenggat. ID W1–W4 = fase 1–4. Satu baris = satu GitHub Issue = satu sesi Claude Code. Kerjakan berurutan dalam fasenya, karena tugas di atas biasanya dibutuhkan tugas di bawahnya. Tugas selesai kalau memenuhi kolom "Selesai bila" dan definition of done di `pengujian-rilis.md`.

Prompt untuk Claude Code cukup: `/kerjakan-backlog W2-03` (atau "Kerjakan W2-03. Ikuti CLAUDE.md.").

**Status:** `Belum` · `Jalan` · `Selesai`. Claude Code mengubah kolom Status saat mulai dan selesai. Isi status yang sebenarnya sebelum sesi pertama kalau sebagian sudah dikerjakan.

Node id frame ada di `figma-frames.md`.

## Fase 1 — fondasi

| ID | Tugas | Acuan | Skill | Selesai bila | Status |
| --- | --- | --- | --- | --- | --- |
| W1-01 | Repo GitHub, proyek Flutter Android, struktur folder, `CLAUDE.md`, `docs/`, `.gitignore` | spesifikasi-teknis, kit ini | — | App kosong jalan di HP | Selesai |
| W1-02 | Pasang paket MVP dan aturan lint | spesifikasi-teknis › Library | — | `flutter analyze` bersih | Selesai |
| W1-03 | Token tema (`AppColors`, `AppText`, `AppSpace`, `AppRadius`), font sebagai aset, `ThemeData` gelap | Foundations 0:1, design-tokens | komponen-ui | Golden test halaman token sama dengan Foundations | Selesai |
| W1-04 | Ekspor 39 ikon SVG jadi widget `AppIcon` | Components [01] 5:7 | komponen-ui | Semua ikon tampil 24px dan bisa diwarnai | Selesai |
| W1-05 | Button, FAB, Input, Checkbox, Switch, Chip, Badge | Components [02] 6:2, [03] 6:30 | komponen-ui | Golden test untuk setiap varian | Selesai |
| W1-06 | Card, Stat Card, Progress Bar, Nav Item, Bottom Nav, Top App Bar, Section Header | Components [04]–[06] | komponen-ui | Golden test untuk setiap varian | Selesai |
| W1-07 | Proyek Supabase dev, login email + kode verifikasi aktif, migrasi semua tabel MVP + RLS | spesifikasi-teknis › Model data, Keamanan data | supabase-tabel | Uji dua akun: A tidak bisa membaca data B | Jalan (uji RLS lulus; tinggal aktifkan email OTP di dashboard oleh Bayu, lihat docs/setup-supabase.md §3) |
| W1-08 | Database drift (tabel MVP + `sync_queue`) dan pola repository | spesifikasi-teknis › Arsitektur | supabase-tabel | Unit test simpan dan baca lokal | Selesai |
| W1-09 | `go_router` dengan shell 5 tab dan semua rute (layar masih kosong berjudul) | navigasi | — | Semua rute bisa dibuka, Back sesuai aturan | Selesai |
| W1-10 | Login email + kode dari 00d, kunci sidik jari 01, PIN H06, G1 sesi berakhir | 00d, 00e Masuk dengan email, 00f Masukkan kode (F-12), 01, H06, G1 | flutter-screen | Buka app → masuk dengan kode → sidik jari → Beranda kosong | Belum |

## Fase 2 — Tugas & Kuliah

| ID | Tugas | Acuan | Skill | Selesai bila | Status |
| --- | --- | --- | --- | --- | --- |
| W2-01 | Task Item, Class Item, Day Pill, Segmented Control, Select, Checklist Item, Action Bar, Overlay Header, Option Item, Date Picker, Time Picker, Snackbar | Components [06], [07], [09], [11] | komponen-ui | Golden test untuk setiap varian | Selesai |
| W2-02 | Repository tugas dan sub-tugas | spesifikasi-teknis › Model data | — | Unit test tambah, ubah, hapus, selesai | Selesai |
| W2-03 | 03 Tugas: kelompok, chip filter, tandai selesai + snackbar Urungkan | 03, E4 | flutter-screen | Kriteria PRD Tugas poin 3–4 | Selesai |
| W2-04 | E2 Tugas kosong | E2 | flutter-screen | Akun baru melihat E2 | Selesai (dibangun bersama W2-03) |
| W2-05 | 15 Tugas baru dengan P01, P02, P03 dan error kolom | 15, P01–P03, G2 | flutter-screen | Kriteria PRD Tugas poin 1–2 | Selesai |
| W2-06 | 16 Detail tugas, H01 Edit tugas, hapus dengan P05 + Urungkan | 16, H01, P05 | flutter-screen | Ubah dan hapus tersimpan | Selesai |
| W2-07 | Repository semester, mata kuliah, jadwal | spesifikasi-teknis › Model data | — | Unit test | Selesai |
| W2-08 | 04 Kuliah: Day Pill, jadwal per hari, status Now dan Done menurut jam | 04 | flutter-screen | Kriteria PRD Kuliah poin 1 | Selesai (K1 ikut dibangun) |
| W2-09 | H02 Jadwal baru (juga mode ubah) dengan P20 | H02, P20 | flutter-screen | Jadwal baru tampil di 04 | Selesai |
| W2-10 | 20 Detail mata kuliah (MVP) dan K1 | Frame "20 Detail Mata Kuliah (MVP)", K1 | flutter-screen | Kriteria PRD Kuliah poin 2–3 | Selesai (K1 dibangun di W2-08) |

## Fase 3 — Keuangan, Beranda, sinkron

| ID | Tugas | Acuan | Skill | Selesai bila | Status |
| --- | --- | --- | --- | --- | --- |
| W3-01 | Wallet Card, Transaction Item, Banner | Components [06], [11] | komponen-ui | Golden test | Selesai |
| W3-02 | Repository dompet, kategori (kategori bawaan seperti di 17), transaksi; hitung saldo | spesifikasi-teknis › Model data | — | Unit test saldo dan ringkasan bulan | Selesai |
| W3-03 | 05 Keuangan (MVP: tanpa chip, Tagihan terdekat, dan ikon Statistik) dan E3 | 05, E3, design-notes §7 | flutter-screen | Kriteria PRD Keuangan poin 2 | Selesai |
| W3-04 | 17 Transaksi baru dengan P06, P07, P01, P02 | 17, P06, P07 | flutter-screen | Transaksi tersimpan kurang dari 10 detik | Selesai |
| W3-05 | H11 Ubah transaksi dan hapus dengan P47 + snackbar Urungkan | H11, P47, E4 | flutter-screen | Kriteria PRD Keuangan poin 3 | Selesai |
| W3-06 | 02 Beranda dengan data asli: Kelas berikutnya, Stat Card, Tugas hari ini, Transaksi terakhir | 02, design-notes §6 | flutter-screen | Kriteria PRD Beranda poin 1 | Belum |
| W3-07 | Mesin sinkron: kirim antrean, tarik perubahan, coba ulang | spesifikasi-teknis › Sinkron offline | — | Uji integrasi offline → online lulus | Belum |
| W3-08 | Banner offline E5, G3 gagal menyimpan, G8 sinkron gagal | E5, G3, G8 | flutter-screen | Ketiga keadaan bisa dipicu dan tampil sesuai frame | Belum |

## Fase 4 — pertama kali, rapikan, rilis

| ID | Tugas | Acuan | Skill | Selesai bila | Status |
| --- | --- | --- | --- | --- | --- |
| W4-01 | Setup awal 01a–01c (tanpa grup Pengingat) | 01a–01c, P20 | flutter-screen | Login pertama → setup → Beranda | Belum |
| W4-02 | E1 Beranda kosong dengan checklist Siapkan Super App | E1 | flutter-screen | Checklist tercentang otomatis dan hilang setelah selesai | Belum |
| W4-03 | Splash native, ikon app adaptif, Intro 00a–00c | 00, Ikon app, 00a–00c | flutter-screen | Tampil di HP sesuai frame | Belum |
| W4-04 | 06 Lainnya (MVP), 14 Pengaturan (MVP), P37, P38, H05 | Frame "06 Lainnya (MVP)", 14, P37, P38, H05 | flutter-screen | Keluar akun dan ganti PIN berjalan | Belum |
| W4-05 | E7 memuat pada layar yang membaca data | E7 | flutter-screen | Tampil saat data belum siap | Belum |
| W4-06 | H04 Pencarian tugas (kalau sempat) | H04 | flutter-screen | Cari judul tugas | Belum |
| W4-07 | Uji integrasi alur utama, uji RLS, cek visual semua layar MVP terhadap Figma | pengujian-rilis | cek-desain | Semua lulus, selisih desain dicatat dan diperbaiki | Belum |
| W4-08 | Proyek Supabase prod, keystore, build APK release, pasang di HP | pengujian-rilis › Checklist rilis Android | — | MVP terpasang di HP dan dipakai sehari-hari | Belum |

## Kalau ingin memakai app lebih cepat

Tunda dulu, sesuai urutan: W4-06 Pencarian, W4-03 Intro 00a–00c, W4-01 Setup awal (cukup langsung ke Beranda kosong), lalu PIN cadangan di W1-10 dan W4-04. Sidik jari, sinkron, dan empat modul inti tetap wajib selesai.

Fase 1 paling berat karena hampir semua komponen dibuat di sana. Kalau terasa terlalu lama sebelum ada layar yang bisa dilihat, komponen yang belum dipakai boleh dipindah ke fase saat layarnya dibuat.

Posisi saat ini (19 Nov 2026): Fase 2 selesai, W3-05 selesai (W1-07 tinggal aktifkan email OTP; W1-10 menunggu desain layar masuk email, F-12); berikutnya W3-06. Sebelum login ada, build debug memakai akun sementara `dev-lokal`. Login diganti dari Google ke email + kode verifikasi.
