# Indeks frame Figma (MVP)

File: `kK09B05WOCxXSf5dvukX41` — https://www.figma.com/design/kK09B05WOCxXSf5dvukX41

Pakai node id ini untuk `get_design_context` / `get_screenshot` (fileKey di atas, nodeId di tabel). Link langsung: `https://www.figma.com/design/kK09B05WOCxXSf5dvukX41?node-id=<id dengan - bukan :>` (contoh 14:127 → `node-id=14-127`).

Node id dicatat 19 Nov 2026. Kalau sebuah id tidak ditemukan, cari frame dengan nama yang sama di halamannya dan perbarui tabel ini.

## Halaman

| Halaman | Node |
| --- | --- |
| Foundations | 0:1 |
| Components | 4:2 |
| Screens — Mobile | 4:3 |
| Screens — Desktop (Tahap 2) | 34:2 |
| Pop-up & Input | 50:180 |
| Landing Page (situs unduhan, `website/`) | 161:2 |

## Komponen (halaman Components)

| Bagian | Node |
| --- | --- |
| [01] Ikon | 5:7 |
| [02] Tombol | 6:2 |
| [03] Form & kontrol | 6:30 |
| [04] Kartu & progres | 7:4 |
| [05] Navigasi | 7:25 |
| [06] Pola layar | 8:34 |
| [07] Pola modul | 21:45 |
| [09] Overlay & input | 49:129 |
| [10] Onboarding | 62:1773 |
| [11] Status & umpan balik | 65:180 |
| [14] Masuk & kode (Code Cell 229:241) | 229:228 |

Komponen baru dan varian yang ditambahkan saat revisi 20 Nov 2026 (`catatan-figma.md` F-01–F-51):

| Komponen / varian | Node |
| --- | --- |
| Icon Button (tombol ikon bulat 40, properti Icon) | 236:228 |
| Bottom Sheet (kerangka pop-up HP, properti Footer) | 236:13583 |
| Select (set): Filled 21:65, Empty, Disabled, Error | 236:252 (236:232, 236:238, 236:245) |
| Input State=Filled | 235:235 |
| Button Danger × Hover, Pressed, Disabled | 235:228, 235:230, 235:232 |
| Foundations › Radius/Item · 16 | 236:13601 |
| Module Tile (set, 21 Nov 2026, F-66): State=Default 9:87, State=Segera | 257:252 (9:87, 257:243) |

## Layar HP MVP

| Kode | Layar | Node |
| --- | --- | --- |
| 00 | Splash | 66:1977 |
| — | Ikon app | 66:1983 |
| 00a–00d | Intro 1–4 | 63:1670, 63:1778, 63:1888, 63:1997 |
| 00e | Masuk dengan email (Section 230:5208) | 230:5209 |
| 00e | Email tidak valid · Mengirim kode · Gagal kirim kode | 230:5235, 230:5261, 230:5287 |
| 00f | Masukkan kode | 231:5271 |
| 00f | Kode salah · Kode kedaluwarsa · Memeriksa kode | 231:5310, 231:5349, 231:5388 |
| 00g | Nama kamu (akun baru, setelah 00f) | 238:5382 |
| 01 | Login / Kunci sidik jari | 12:2 |
| 01a | Jadwal semester | 66:1786 |
| 01b | Dompet & saldo awal | 66:1852 |
| 01c | Keamanan & pengingat | 66:1898 |
| 02 | Beranda | 13:14 |
| 03 | Tugas | 14:127 |
| 04 | Kuliah | 15:218 |
| 05 | Keuangan | 16:300 |
| 06 | Lainnya (MVP, modul segera) — **pakai ini** (F-66) | 257:6514 |
| 06 | Lainnya (MVP) — versi kosong v0.1.0, tidak dipakai lagi | 158:15114 |
| 14 | Pengaturan | 27:1092 |
| 15 | Tambah Tugas | 30:1381 |
| 16 | Detail Tugas | 30:1472 |
| 17 | Tambah Transaksi | 31:1482 |
| 20 | Detail Mata Kuliah (MVP) — **pakai ini** | 158:15146 |

## Keadaan kosong, status, gagal

| Kode | Layar | Node |
| --- | --- | --- |
| E1 | Beranda kosong | 67:1902 |
| E2 | Tugas kosong | 67:1978 |
| E3 | Keuangan kosong | 67:2026 |
| E4 | Snackbar urungkan | 67:2114 |
| E5 | Beranda offline | 68:2132 |
| E7 | Memuat | 68:2289 |
| K1 | Kuliah kosong | 140:4698 |
| G1 | Sesi berakhir | 137:4097 |
| G2 | Isian belum lengkap | 137:4349 |
| G3 | Gagal menyimpan | 137:4395 |
| G8 | Sinkron gagal | 137:4901 |

## Pop-up & halaman penuh MVP

| Kode | Tampilan | Node |
| --- | --- | --- |
| P01 | Pilih tanggal | 50:326 |
| P02 | Pilih jam | 50:393 |
| P03 | Pilih mata kuliah | 50:483 |
| P05 | Konfirmasi hapus | 50:611 |
| P06 | Pilih dompet | 51:617 |
| P07 | Dompet baru | 51:691 |
| P20 | Pilih semester | 85:4227 |
| P37 | Akun | 88:5795 |
| P38 | Keluar akun | 88:5875 |
| P47 | Hapus transaksi | 185:13574 |
| H01 | Edit tugas | 54:2269 |
| H02 | Jadwal baru | 54:2356 |
| H04 | Pencarian | 56:2409 |
| H05 | Atur PIN cadangan | 56:2490 |
| H06 | Masukkan PIN | 56:2560 |
| H11 | Ubah transaksi | 185:13492 |

## Keadaan tambahan (revisi 20 Nov 2026)

Frame keadaan yang ditambahkan dari `catatan-figma.md`. Letaknya di section "Revisi · …" di bawah halaman masing-masing; tiap section punya kotak Catatan berisi aturan layarnya.

| Kode | Keadaan | Node |
| --- | --- | --- |
| — | Section Revisi · masuk & kunci (Screens) | 238:5381 |
| 00f | Offline saat memeriksa / gagal kirim ulang · Kirim ulang tersedia | 238:5410, 238:5456 |
| 01 | Tanpa nama · Belum tersinkron | 238:5495, 238:5734 |
| G1 | Belum pernah sinkron | 238:5976 |
| — | Catatan · masuk & kunci | 238:6226 |
| — | Section Revisi · Beranda & Tugas (Screens) | 239:5481 |
| 02 | Tanpa nama, tanpa tugas hari ini | 239:5482 |
| 03 | Kelompok Nanti (di frame 03 14:127) · Filter tanpa hasil | 239:5471, 239:5533 |
| E4 | Snackbar tugas selesai | 239:5660 |
| E5 | Offline tanpa perubahan menunggu | 239:5771 |
| 15 | Isian awal · Tanpa tanggal · Mengetik sub-tugas | 241:5764, 241:5848, 241:5920 |
| 16 | Tugas selesai · Tanpa deadline & data opsional | 241:5999, 241:6094 |
| — | Catatan · 03 Tugas · 02 Beranda & E5 · 15 dan 16 | 241:6213, 241:6220, 241:6227 |
| — | Section Revisi · Kuliah & Keuangan (Screens) | 241:6235 |
| 04 | Hari tanpa kelas | 241:6236 |
| 20 | Tanpa tugas aktif | 241:6354 |
| 05 | Snackbar transaksi dihapus | 241:6417 |
| 17 | Pemasukan · Nominal kosong · Nominal wajib diisi · Tidak fokus + tanggal lain | 241:6539, 241:6613, 241:6655, 241:6698 |
| — | Catatan · 04 dan 20 · 05 dan 17 | 241:6832, 241:6839 |
| — | Section Revisi · pop-up & halaman penuh (Pop-up & Input) | 242:7910 |
| P03 | Belum ada mata kuliah | 242:7911 |
| P05 | Tanpa sub-tugas | 242:8060 |
| P07 | Nama dompet kosong | 242:8148 |
| P20 | Belum ada semester | 242:8269 |
| P47 | Hapus pemasukan | 242:8384 |
| H02 | Ubah jadwal · Isian salah | 242:8480, 242:8574 |
| — | Catatan · pop-up (P03, P05, P07, P20, H02, H06) | 242:8677 |

## Situs unduhan (halaman Landing Page 161:2)

Bukan layar app. Dibangun di `website/` (HTML/CSS statis). Desktop dipakai mulai lebar 1024 px.

| Halaman situs | Desktop 1440 | HP 412 | File |
| --- | --- | --- | --- |
| Landing | 161:3 | 164:777 | `website/index.html` |
| Unduh Android | 177:1266 | 177:1338 | `website/unduh/android/index.html` |
| 404 | 182:1665 | 182:1702 | `website/404.html` |
| Menu terbuka | — | 183:1805 | menu di semua halaman |
| Unduh Windows, Catatan rilis, Laporkan masalah, Laporan terkirim, Kebijakan privasi | 178:1340, 179:1409, 180:1490, 182:1594, 183:1686 | 178:1409, 179:1491, 180:1580, 182:1633, 183:1754 | Belum dibangun (F-64) |

Komponen situs ada di halaman Components: LP / Nav (176:1329, 176:1348), LP / Footer (176:1344, 176:1361), LP / Logo (160:224), LP / Stat (160:228), LP / Feature Card (160:235), LP / Feature Row (186:240), LP / Step Card (160:242), LP / Step Row (186:247), LP / FAQ Item (160:246), LP / FAQ Row (186:264).
