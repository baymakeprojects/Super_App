# Token Figma → Flutter

Nama di kode mengikuti nama variabel di halaman Foundations (node 0:1), supaya output Figma bisa dicocokkan langsung dengan token. Kalau nilai di Figma berbeda dengan tabel ini, Figma yang benar — laporkan selisihnya.

## Warna — `lib/core/theme/app_colors.dart`

| Variabel Figma | Nilai | Nama Dart | Dipakai untuk |
| --- | --- | --- | --- |
| Primary | #000000 | `AppColors.primary` | Latar halaman |
| Surface/Raised | #0D0D0D | `AppColors.surfaceRaised` | Kartu dan panel |
| Surface/Card | #1E1E1E | `AppColors.surfaceCard` | Kartu menonjol, track progress |
| Dark Gray | #333333 | `AppColors.darkGray` | Garis dan border |
| Gray | #8A8A8A | `AppColors.gray` | Label, keterangan, placeholder |
| Light Gray | #A7A7A7 | `AppColors.lightGray` | Teks sekunder |
| White | #F9F9F9 | `AppColors.white` | Teks utama |
| Branding Orange | #E85002 | `AppColors.brandingOrange` | Tombol utama, ikon aktif |
| Accent Text | #E85002 | `AppColors.accentText` | Teks oranye kecil |
| On Accent | #000000 | `AppColors.onAccent` | Teks dan ikon di atas oranye |
| Status/Success | #4FAE68 | `AppColors.success` | Pemasukan, selesai |
| Status/Warning | #E3C46A | `AppColors.warning` | Deadline dekat, budget hampir habis |
| Status/Danger | #FF5A5F | `AppColors.danger` | Pengeluaran, terlambat, error |
| Gradient/Sand, Flame, Red | #D9C3AB, #F16001, #C10801 | `AppColors.gradientSand`, `gradientFlame`, `gradientRed` | Warna gradasi; Flame untuk hover, Red untuk ditekan |
| Gradient/Branding (paint style) | Sand 0% → Flame 22% → Red 55% → Primary 100%, kiri ke kanan | `AppColors.gradientBranding` | Kartu Total saldo dan tempat lain yang ada di Figma |

## Teks — `lib/core/theme/app_text.dart`

Di Flutter, tinggi baris ditulis sebagai `height = tinggi baris ÷ ukuran`; letter spacing sama dengan angka Figma.

| Gaya Figma | Font | Ukuran / tinggi baris / spasi huruf | Nama Dart |
| --- | --- | --- | --- |
| Display/Large | Doto Black | 48 / 48 / −1 | `AppText.displayLarge` |
| Display/Medium | Doto Black | 36 / 38 / 0 | `AppText.displayMedium` |
| Display/Small | Doto Black | 28 / 30 / 0 | `AppText.displaySmall` |
| Heading/Large | Geist Medium | 28 / 34 / −0,8 | `AppText.headingLarge` |
| Heading/Medium | Geist Medium | 22 / 28 / −0,3 | `AppText.headingMedium` |
| Heading/Small | Geist Medium | 18 / 24 / −0,2 | `AppText.headingSmall` |
| Title/Medium | Geist Medium | 16 / 22 / 0 | `AppText.titleMedium` |
| Body/Large | Geist Regular | 16 / 24 / 0 | `AppText.bodyLarge` |
| Body/Medium | Geist Regular | 14 / 20 / 0 | `AppText.bodyMedium` |
| Body/Small | Geist Regular | 12 / 16 / 0 | `AppText.bodySmall` |
| Label/Large | Geist Mono SemiBold, kapital | 13 / 18 / 1 | `AppText.labelLarge` |
| Label/Medium | Geist Mono Regular, kapital | 11 / 16 / 1,5 | `AppText.labelMedium` |
| Label/Small | Geist Mono Regular, kapital | 10 / 14 / 1,5 | `AppText.labelSmall` |

Label disimpan dalam huruf biasa dan diubah ke kapital di widget.

## Spasi & sudut — `lib/core/theme/app_spacing.dart`

- Spasi: `AppSpace.s4`, `s8`, `s12`, `s16`, `s20`, `s24`, `s32` (variabel Spacing/4 sampai Spacing/32).
- Sudut: `AppRadius.input` 10, `button` 12, `item` 16, `card` 20, `full` 999 (variabel Radius/…).

## Font

Doto, Geist, dan Geist Mono (semuanya Google Fonts, lisensi OFL) diunduh sekali dan disimpan di `assets/fonts/`, lalu didaftarkan di `pubspec.yaml`. Jangan memakai paket google_fonts saat app jalan.
