# Super App — aturan proyek

App Flutter pribadi (Android dulu, Windows di Tahap 2) untuk kuliah, tugas, dan keuangan.
Backend Supabase, database lokal drift, offline-first. Pemilik: Bayu.
Tanpa tenggat: MVP dikerjakan berurutan per fase sampai selesai. Bayu baru mulai ngoding
dan sambil belajar Flutter, jadi jelaskan keputusan teknis dengan singkat dan jelas.

## Baca dulu
- docs/prd.md — apa yang dibangun di MVP dan kriteria selesainya.
- docs/spesifikasi-teknis.md — library, arsitektur, model data, sinkron.
- docs/design-notes.md — cara membaca Figma dan aturan per layar. WAJIB sebelum membuat layar/komponen.
- docs/design-tokens.md — token warna, teks, spasi, sudut (nama Figma → nama Dart).
- docs/navigasi.md — semua rute go_router dan pop-up MVP. Jangan menambah rute di luar tabel itu.
- docs/figma-frames.md — node id tiap frame Figma MVP.
- docs/backlog.md — daftar tugas MVP (W1-01 … W4-08) beserta statusnya.
- docs/catatan-figma.md — desain Figma yang salah/kurang/tidak ada, untuk diperbaiki nanti.
- docs/pengujian-rilis.md — definition of done dan checklist rilis.

## Desain: Figma adalah sumber kebenaran
- File: https://www.figma.com/design/kK09B05WOCxXSf5dvukX41
  Halaman: Foundations 0:1, Components 4:2, Screens Mobile 4:3,
  Screens Desktop 34:2, Pop-up & Input 50:180.
- Sebelum membuat atau mengubah layar, ambil frame-nya dengan
  get_design_context dan get_screenshot (Figma MCP). Node id ada di docs/figma-frames.md.
- Jangan menambah elemen, teks, warna, ikon, animasi, atau layar
  yang tidak ada di Figma. Kalau desain tidak jelas, saling bertentangan,
  atau tampak salah, berhenti dan tanya. Jangan menebak.
- Elemen yang ditandai "Perlu keputusan" di docs: tanya dulu.
- Setiap menemukan desain Figma yang salah, kurang, tidak konsisten, atau
  tidak ada (termasuk keadaan atau varian yang belum didesain), catat di
  docs/catatan-figma.md supaya Figma diperbaiki nanti. Tetap tanya dulu
  kalau memengaruhi kode.
- Teks di layar disalin persis dari Figma (Bahasa Indonesia).
- Hanya mode gelap. Jangan membuat tema terang.
- Warna, font, spasi, dan sudut hanya dari lib/core/theme
  (namanya mengikuti variabel Figma). Dilarang Color(0x...),
  angka ukuran, atau TextStyle baru langsung di layar.
- Pakai widget lib/core/ui yang sesuai komponen Figma. Kalau belum ada,
  buat dulu di core/ui dari halaman Components, baru dipakai di layar.
- Output get_design_context (React + Tailwind) hanya referensi;
  tulis ulang sebagai widget Flutter.
- Ukuran acuan: HP 412x917 (lebar mengikuti HP, jangan dikunci 412).
- Setiap keadaan punya frame sendiri (kosong E/K, memuat E7, gagal G).
  Bangun semuanya, jangan buat versi sendiri.
- Elemen Tahap 2–3 di layar MVP disembunyikan utuh (lihat design-notes §7).
- Setelah selesai, bandingkan screenshot app dengan frame Figma
  dan laporkan selisihnya (skill cek-desain).

## Kode
- Struktur: lib/features/<fitur>/{presentation,application,data}.
  Layar tidak memanggil Supabase langsung, selalu lewat repository.
- State Riverpod, navigasi go_router, database drift.
- Semua tabel Supabase punya user_id dan Row Level Security;
  perubahan database hanya lewat file di supabase/migrations.
- Hapus = isi deleted_at (soft delete), bukan hapus permanen.
- Nominal uang = bigint rupiah. Saldo dompet dihitung, tidak disimpan.
- App tidak punya fitur AI. Jangan menambahkan fitur AI apa pun.
- Jangan menambah paket baru tanpa bertanya.
- Jangan membaca atau menulis env/, keystore, atau kunci service role.
- Untuk perubahan besar, tulis rencana singkat dulu dan tunggu persetujuan.
- Sebelum bilang selesai: dart format, flutter analyze, flutter test.

## Cara kerja per tugas
- Satu tugas backlog = satu branch = satu sesi. Pakai skill kerjakan-backlog.
- Layar baru: skill flutter-screen. Komponen core/ui: skill komponen-ui.
- Tabel baru: skill supabase-tabel. Cek visual: skill cek-desain.
- Setelah selesai, ubah status tugas di docs/backlog.md.

## Bahasa
- Penjelasan ke pengguna dalam Bahasa Indonesia.
- Nama variabel, kelas, dan file dalam bahasa Inggris.
