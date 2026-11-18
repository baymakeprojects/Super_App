---
name: kerjakan-backlog
description: Kerjakan satu tugas dari docs/backlog.md (misalnya W2-03) dari awal sampai selesai — baca acuan, buat branch, rencana, kode, tes, dan ubah status. Pakai saat Bayu menyebut ID backlog seperti W1-03 atau "kerjakan tugas berikutnya".
argument-hint: "[ID backlog, misalnya W2-03]"
---

# Kerjakan tugas backlog

Tugas yang diminta: **$ARGUMENTS** (kalau kosong, ambil tugas pertama berstatus `Belum` di `docs/backlog.md` dan konfirmasi ke Bayu dulu).

## 1. Pahami tugasnya
1. Baca baris tugas di `docs/backlog.md`: kolom Tugas, Acuan, Skill, dan "Selesai bila".
2. Cek tugas di atasnya dalam fase yang sama. Kalau ada yang belum `Selesai` dan dibutuhkan tugas ini, beri tahu Bayu dan tanya mau lanjut atau kerjakan yang itu dulu.
3. Baca dokumen di kolom Acuan, plus `docs/prd.md` bagian yang terkait (kriteria selesai).
4. Kalau acuan berupa frame Figma, cari node id-nya di `docs/figma-frames.md`.

## 2. Siapkan
1. Pastikan working tree bersih (`git status`). Kalau tidak bersih, tanya dulu.
2. Buat branch: `git checkout -b <id-kecil>-<ringkasan>` (contoh `w2-03-layar-tugas`).
3. Ubah status tugas di `docs/backlog.md` jadi `Jalan`.

## 3. Rencana
Tulis rencana singkat (5–10 baris) ke Bayu: file yang dibuat/diubah, komponen `core/ui` yang dipakai atau perlu dibuat, tabel/repository yang disentuh, tes yang ditulis, dan pertanyaan yang belum jelas. **Tunggu persetujuan** sebelum menulis kode, kecuali tugasnya sangat kecil (satu file).

## 4. Kerjakan
- Pakai skill yang tertulis di kolom Skill:
  - `flutter-screen` untuk layar dan keadaannya.
  - `komponen-ui` untuk widget `core/ui` dan token.
  - `supabase-tabel` untuk tabel, migrasi, drift, dan repository.
- Ikuti semua aturan di `CLAUDE.md`.
- Jangan mengerjakan hal di luar baris backlog ini. Kalau menemukan masalah lain, catat sebagai saran di laporan akhir.

## 5. Periksa
1. `dart format .`, `flutter analyze`, `flutter test` — semua bersih.
2. Cocokkan dengan kolom "Selesai bila" dan definition of done di `docs/pengujian-rilis.md`.
3. Untuk layar: jalankan skill `cek-desain`.
4. Yang tidak bisa diperiksa dari sini (misalnya sidik jari di HP asli), tulis sebagai langkah uji manual untuk Bayu.

## 6. Tutup
1. Ubah status di `docs/backlog.md` jadi `Selesai` (atau tetap `Jalan` dengan catatan kalau ada yang tertunda).
2. Commit kecil dengan pesan Bahasa Indonesia, awali dengan ID: `W2-03: layar Tugas dengan filter dan urungkan`.
3. Jangan push atau merge tanpa diminta.
4. Laporan ke Bayu: apa yang selesai, cara mengujinya di HP, selisih desain yang tersisa, dan tugas berikutnya.
