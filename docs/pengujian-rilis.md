# Pengujian & rilis

Cara memastikan tiap fitur benar dan sama dengan desain, lalu cara merilisnya ke HP sendiri dan nanti ke teman.

## Jenis pengujian

| Jenis | Yang diuji | Alat | Kapan |
| --- | --- | --- | --- |
| Unit | Format Rp dan tanggal, hitung saldo, logika antrean sinkron | `flutter test` | Setiap fitur |
| Widget | Komponen `core/ui` sama dengan Figma: warna, ukuran, teks | `flutter test` + golden test | Setiap komponen baru |
| Integrasi | Login → tambah tugas → matikan internet → online lagi → tersinkron | `integration_test` di HP atau emulator | Sebelum rilis |
| Keamanan data | Akun A tidak bisa membaca atau mengubah data akun B | Dua akun uji di proyek dev | Setiap tabel baru |
| Visual | Setiap layar dibandingkan dengan frame Figma-nya | Screenshot app vs screenshot Figma (skill cek-desain) | Setiap layar selesai |
| Manual | Dipakai sehari penuh di HP sendiri | HP Android | Setiap fitur |

## Cek terhadap desain Figma

Setiap layar dicek berdampingan dengan frame Figma-nya, termasuk tampilan kosong, memuat, dan gagal. Yang harus sama:

- Warna, font, ukuran teks, dan tinggi baris dari token.
- Jarak dan ukuran (kelipatan 4) serta sudut (10, 12, 16, 20, pil).
- Teks persis seperti di Figma, termasuk huruf kapital pada label.
- Ikon, urutan elemen, dan tombol yang tampil.

Golden test untuk komponen `core/ui` menangkap perubahan tampilan yang tidak disengaja.

## Definition of done per fitur

- [ ] Semua kriteria selesai di PRD tercentang.
- [ ] Layar dan semua keadaannya (kosong, memuat, gagal) sama dengan Figma.
- [ ] Jalan tanpa internet dan tersinkron saat online lagi.
- [ ] Tidak ada warna, ukuran, atau gaya teks yang ditulis langsung di luar token.
- [ ] `dart format`, `flutter analyze`, dan `flutter test` bersih.
- [ ] Sudah dipakai di HP sendiri minimal satu hari.

## Checklist rilis Android

Langkah lengkapnya (proyek prod, keystore, build, pasang) ada di `docs/rilis-android.md`.

APK untuk Releases dibangun dan ditandatangani oleh GitHub Actions saat tag `v*` didorong; langkah dan daftar GitHub Secrets ada di [`rilis.md`](rilis.md).

- [ ] Naikkan versi di `pubspec.yaml`, misalnya `0.3.0+12` (versi + nomor build).
- [ ] Pastikan app memakai proyek Supabase prod.
- [ ] Build `flutter build apk --release` untuk dipasang langsung, atau `flutter build appbundle` untuk Google Play.
- [ ] Tanda tangani dengan keystore sendiri. Simpan keystore dan sandinya di luar repo dan buat cadangan; kalau hilang, versi baru tidak bisa dipasang di atas versi lama.
- [ ] Uji pasang bersih dan uji update di atas versi sebelumnya.
- [ ] Cek izin (permissions) seminimal mungkin.
- [ ] Tulis catatan rilis singkat.

Untuk membagikan APK ke orang lain, perlu [verifikasi developer Android](https://support.google.com/android-developer-console/answer/16561738): sejak September 2026 aturan ini berlaku di Indonesia untuk semua app yang dipasang di perangkat Android bersertifikat.

## Checklist rilis Windows (Tahap 2)

- [ ] Build `flutter build windows`, lalu bungkus jadi installer (MSIX atau Inno Setup).
- [ ] Tanpa sertifikat code signing, Windows SmartScreen menampilkan peringatan; tulis cara melewatinya di halaman download.

## Versi & distribusi

- Versi 0.x selama dipakai sendiri; 1.0.0 saat teman mulai memakai.
- Tabel `app_versions` di Supabase menyimpan versi terbaru, versi minimal, dan link unduh. App memeriksanya saat dibuka dan memberi tahu kalau ada update.
- Untuk teman: Google Play uji tertutup (12 penguji selama 14 hari untuk akun personal baru) atau APK dari landing page.

## Pelacakan bug

Catat di GitHub Issues dengan label `bug`, `fitur`, atau `desain`. Setiap bug berisi langkah mengulang, hasil, harapan, dan screenshot; bug desain juga menyertakan link frame Figma-nya.
