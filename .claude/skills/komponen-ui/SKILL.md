---
name: komponen-ui
description: Buat atau ubah token tema (lib/core/theme) dan widget komponen (lib/core/ui) dari halaman Foundations dan Components Figma Super App, lengkap dengan golden test. Pakai saat membangun Button, Input, Card, Task Item, Bottom Nav, ikon, atau komponen Figma lain.
argument-hint: "[nama komponen Figma, misalnya Button atau Task Item]"
---

# Komponen core/ui dari Figma

Komponen: **$ARGUMENTS**

## 1. Ambil spesifikasi
1. Cari bagian komponen di `docs/figma-frames.md` (halaman Components 4:2; [02] Tombol 6:2, [03] Form 6:30, dst.).
2. `get_metadata` pada bagian itu untuk menemukan node COMPONENT / COMPONENT_SET-nya, lalu `get_design_context` + `get_screenshot` pada komponen tersebut. Untuk token, pakai `get_variable_defs` di Foundations 0:1.
3. Catat semua varian dan properti (misalnya Type × State). Baca catatan komponen di `docs/design-notes.md` §4.
4. Abaikan frame specimen, label abu, dan teks penjelasan di sekitar komponen.

## 2. Token dulu
- Semua nilai harus berasal dari `lib/core/theme` (`AppColors`, `AppText`, `AppSpace`, `AppRadius`) sesuai `docs/design-tokens.md`.
- Kalau komponen butuh nilai yang belum ada di token tapi ada sebagai variabel Figma: tambahkan ke token dengan nama variabel Figma. Kalau nilainya tidak ada di variabel Figma: tanya Bayu, lalu catat di `docs/catatan-figma.md`. Varian atau keadaan yang belum didesain (misalnya Disabled, Hover) juga dicatat di sana.

## 3. Tulis widget
- Satu komponen Figma = satu widget di `lib/core/ui/<nama_snake>.dart`, nama kelas `App<Nama>` atau sesuai nama Figma (misalnya `TaskItem`, `AppButton`).
- Varian Figma = parameter (enum) widget, bukan widget terpisah.
- Jangan membungkus widget Material dengan tampilan bawaannya: tidak ada ripple berwarna, elevasi, bayangan, atau warna Material.
- Ikon dari `AppIcon` (SVG hasil ekspor Components [01]); jangan Material Icons.
- Label Geist Mono dikapitalkan di dalam widget.
- Ukuran mengikuti konten seperti auto-layout Figma (hug/fill), bukan lebar tetap, kecuali Figma memakai ukuran tetap (misalnya FAB 56×56).
- Ekspor dari `lib/core/ui/ui.dart` supaya layar cukup satu import.

## 4. Golden test
- `test/core/ui/<nama>_test.dart`: render setiap varian di latar hitam dengan font asli (muat dari `assets/fonts` di test setup).
- Simpan golden di `test/core/ui/goldens/`. Jalankan `flutter test --update-goldens` hanya saat membuat golden baru atau perubahan disengaja.
- Bandingkan golden dengan screenshot Figma; laporkan selisih yang terlihat.

## 5. Halaman katalog (opsional tapi disarankan)
Tambahkan komponen ke layar debug `lib/core/ui/catalog_page.dart` (hanya di build debug) supaya Bayu bisa melihat semua varian di HP.

## 6. Selesai
`dart format .`, `flutter analyze`, `flutter test`. Laporkan varian yang dibuat dan selisih dengan Figma.
