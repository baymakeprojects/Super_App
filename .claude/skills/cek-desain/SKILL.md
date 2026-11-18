---
name: cek-desain
description: Bandingkan layar atau komponen Flutter yang sudah dibuat dengan frame Figma-nya dan tulis daftar selisih (warna, teks, jarak, sudut, ikon, keadaan yang terlewat). Pakai setelah layar selesai, sebelum commit, atau saat Bayu bilang tampilannya beda dengan Figma.
argument-hint: "[kode layar atau nama komponen]"
---

# Cek desain terhadap Figma

Yang dicek: **$ARGUMENTS**

## 1. Ambil kedua tampilan
1. Figma: node id dari `docs/figma-frames.md` → `get_screenshot` (dan `get_design_context` untuk angka persisnya). Sertakan frame keadaan terkait (E/K/G) dan pop-up.
2. App: ambil screenshot layar yang sama di lebar 412 dp.
   - Cara paling andal: widget/golden test yang merender layar dengan data contoh yang sama seperti Figma, ukuran 412×917, font asli.
   - Kalau emulator jalan: `flutter screenshot` atau `adb exec-out screencap -p > shot.png`.
   - Kalau tidak bisa mengambil screenshot app, katakan begitu dan lakukan cek kode saja (langkah 3). Jangan mengaku sudah membandingkan gambar.

## 2. Bandingkan berdampingan
Periksa satu per satu:
- Warna latar, kartu, garis, teks, status — sama dengan token.
- Font, ukuran, tebal, tinggi baris, letter spacing, huruf kapital label.
- Jarak tepi, jarak antarelemen (kelipatan 4), ukuran elemen, sudut (10/12/16/20/pil).
- Ikon (bentuk dan ukuran 24), urutan elemen, tombol yang tampil.
- Teks label persis sama; teks data berasal dari data, bukan hardcode.
- Elemen Tahap 2–3 disembunyikan sesuai `docs/design-notes.md` §7.
- Semua keadaan yang punya frame sudah dibangun.

## 3. Cek kode
- Cari angka warna/ukuran mentah di layar: `Color(0x`, `fontSize:`, `EdgeInsets.all(<angka>`, `BorderRadius.circular(<angka>` di luar `lib/core/theme`.
- Cari widget Material dengan tampilan bawaan (`AppBar(`, `TextField(`, `Checkbox(`, `SnackBar(`, `showDatePicker`) di `lib/features`.
- Cari teks contoh Figma yang ditulis langsung (misalnya "Bayu", "Pemrograman Mobile", "Rp").

## 4. Laporan
Tabel: Bagian · Figma · App · Tingkat (besar/kecil) · Perbaikan. Perbaiki yang besar langsung kalau masih dalam lingkup tugas; sisanya serahkan ke Bayu. Kalau tidak ada selisih, katakan begitu dan sebutkan apa saja yang sudah dicek.

Kalau selisihnya karena **Figma** yang salah, kurang, tidak konsisten, atau tidak ada (bukan kesalahan kode), tambahkan ke `docs/catatan-figma.md`.
