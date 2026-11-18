---
name: flutter-screen
description: Bangun atau ubah satu layar Flutter Super App persis dari frame Figma-nya, termasuk keadaan kosong, memuat, gagal, dan pop-up yang dibuka dari layar itu. Pakai setiap kali membuat atau mengubah layar (kode 00–20, E, G, K, H, P).
argument-hint: "[kode layar atau link frame Figma]"
---

# Bangun layar dari Figma

Layar: **$ARGUMENTS**

Kalau plugin Figma terpasang, muat juga skill `figma-design-to-code` dari plugin itu sebelum memanggil `get_design_context`.

## 1. Kumpulkan acuan
1. Cari node id layar di `docs/figma-frames.md` (fileKey `kK09B05WOCxXSf5dvukX41`). Untuk 06 dan 20 pakai frame **(MVP)**.
2. Baca bagian layar ini di `docs/design-notes.md` §6 dan cek tabel §7 (elemen yang disembunyikan di MVP).
3. Baca baris rutenya di `docs/navigasi.md`: rute, dari mana dibuka, ke mana kembali, pop-up apa saja.
4. Panggil `get_screenshot` dan `get_design_context` untuk frame layar, lalu untuk setiap frame keadaan (E/K/G) dan pop-up (P/H) yang terkait.
5. Kalau ada yang tidak jelas atau bertentangan, berhenti dan tanya Bayu.

## 2. Petakan ke komponen
1. Daftar setiap elemen di frame → widget `lib/core/ui` yang sesuai (nama komponen Figma = nama widget).
2. Komponen yang belum ada: buat dulu dengan skill `komponen-ui`, jangan dibuat ad hoc di layar.
3. Daftar setiap nilai warna/teks/spasi/sudut → token di `lib/core/theme` (`docs/design-tokens.md`). Nilai yang tidak cocok dengan token mana pun: laporkan, jangan pakai angka mentah.
4. Tandai teks contoh (nama, nominal, tanggal, mata kuliah) — semuanya harus dari data, bukan ditulis langsung.

## 3. Tulis kode
- File di `lib/features/<fitur>/presentation/`. State dan aksi di `application/` (Riverpod). Data lewat repository di `data/`.
- Output `get_design_context` (React + Tailwind) hanya referensi; tulis ulang sebagai widget Flutter.
- Bangun semua keadaan yang punya frame: data ada, kosong, memuat (E7), gagal (G), offline (E5) kalau relevan.
- Pop-up: bottom sheet lewat `showModalBottomSheet` + Overlay Header; halaman penuh (H) sebagai rute.
- Teks label disalin persis dari Figma. Label (Label/…) disimpan huruf biasa, dikapitalkan di widget.
- Format uang/tanggal/jam lewat util di `lib/core/utils` (locale id_ID).
- Jangan menambah elemen, animasi, atau teks yang tidak ada di Figma. Elemen Tahap 2–3 disembunyikan utuh.
- Lebar mengikuti HP; jangan kunci 412. Hormati safe area; jangan gambar status bar.

## 4. Tes
- Widget test untuk keadaan utama (ada data, kosong, gagal) dengan provider palsu.
- Unit test untuk logika baru di application/data.

## 5. Selesai
Jalankan skill `cek-desain` untuk layar ini, lalu `dart format .`, `flutter analyze`, `flutter test`. Laporkan selisih yang tersisa.
