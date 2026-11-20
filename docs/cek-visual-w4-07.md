# Cek visual semua layar MVP (W4-07, 20 Nov 2026)

Setiap golden test layar (412×917, font asli, status bar 32) dibandingkan per piksel dengan screenshot frame Figma terbaru. Angka = persen piksel yang bedanya terlihat (selisih warna > 60 dari 255). Bagian status bar tidak dihitung.

Di bawah sekitar 2%: hanya beda halusnya huruf (anti-aliasing) antara Figma dan Flutter. Di atasnya: selalu ada penyebab yang dicatat di kolom terakhir.

| Layar | Frame | Beda | Penyebab selisih |
| --- | --- | --- | --- |
| 00d Intro 4 | 63:1997 | 0,97% | Huruf |
| 00e Masuk (4 keadaan) | 230:5209, 5235, 5261, 5287 | 0,66–0,77% | Huruf |
| 00f Kode (4 keadaan) | 231:5271, 5310, 5349, 5388 | 0,73–0,85% | Huruf |
| 01 Kunci sidik jari | 12:2 | 0,86% | Huruf |
| G1 Sesi berakhir | 137:4097 | 0,62% | Teks "Google" diganti "email" (F-13) |
| H06 Masukkan PIN | 56:2560 | 0,37% | Teks "Google" diganti "email" (F-13) |
| 01a, 01b Setup | 66:1786, 66:1852 | 1,24%, 1,15% | Huruf |
| 01c Setup keamanan | 66:1898 | 2,30% | Grup Pengingat disembunyikan (Tahap 2) |
| 02 Beranda | 13:14 | 1,96% | Ikon lonceng disembunyikan (Tahap 2) |
| E1, E5, G8 Beranda | 67:1902, 68:2132, 137:4901 | 1,60–1,78% | Ikon lonceng; teks widget di E1 (F-53) |
| E7 Memuat | 68:2289 | 0,38% | Ikon lonceng |
| 03 Tugas, E2, E4, G2 | 14:127, 67:1978, 67:2114, 137:4349 | 0,62–1,97% | Huruf |
| 15 Tugas baru | 30:1381 | 1,68% | Baris "Ingatkan saya" disembunyikan |
| 16 Detail tugas | 30:1472 | 5,38% | Baris pengingat dan Lampiran disembunyikan (Tahap 2) |
| H01 Edit tugas | 54:2269 | 3,33% | Data contoh tes berbeda (sub-tugas, catatan); tampilan sama |
| H04 Pencarian | 56:2409 | 4,31% | Chip dan hasil modul Tahap 2–3 disembunyikan (F-57) |
| P01, P02, P05 | 50:326, 50:393, 50:611 | 0,31–1,53% | Huruf |
| P03 Pilih mata kuliah | 50:483 | 0,59% | Diperbaiki di W4-07 (Option Item, F-18) |
| 04 Kuliah, K1 | 15:218, 140:4698 | 2,64%, 0,84% | Ikon Materi dan "Catatan terakhir" disembunyikan |
| 20 Detail mata kuliah (MVP) | 158:15146 | 0,68% | Huruf |
| H02 Jadwal baru | 54:2356 | 1,49% | Huruf |
| P20 Pilih semester | 85:4227 | 2,65% | Latar di Figma sekarang 01a, di tes H02; sheet sama |
| 05 Keuangan | 16:300 | 14,26% | Chip, ikon Statistik, "Tagihan terdekat" disembunyikan (Tahap 2); isi tes lebih banyak |
| E3 Keuangan kosong | 67:2026 | 7,36% | Baris chip disembunyikan, isi naik 66 px |
| 17 Transaksi baru, G3, H11, P47 | 31:1482, 137:4395, 185:13492, 185:13574 | 0,54–1,53% | Huruf |
| P06 Pilih dompet | 51:617 | 0,45% | Diperbaiki di W4-07 (Option Item, F-18) |
| P07 Dompet baru | 51:691 | 3,72% | "Hitung di total saldo" disembunyikan (F-43) |
| 14 Pengaturan | 27:1092 | 4,08% | Grup Data, Notifikasi, Bottom Nav disembunyikan (F-55) |
| P37, P38 | 88:5795, 88:5875 | 2,03%, 1,25% | Daftar perangkat dan Wi-Fi disembunyikan (F-55) |
| H05 Atur PIN | 56:2490 | 0,70% | Huruf |

Belum dibandingkan per piksel: 06 Lainnya (MVP), karena build debug menampilkan daftar rute debug di layar itu.

## Yang diperbaiki di W4-07

- Option Item (P03, P06, P20): Default sekarang bergaris 1px transparan seperti komponen Figma terbaru, jadi tingginya 70 sama dengan Selected (F-18).
- Tautan E3 "Atau isi lewat setup awal" membuka Beranda, bukan 01b, karena router mengalihkan rute setup setelah setup selesai (bug W4-01). Sekarang layar setup boleh dibuka lagi.

## Uji lain di W4-07

- Integrasi (`test/integration/main_flow_test.dart`, jalan dengan `flutter test`): masuk dengan kode → Setup awal → Lewati → tambah tugas saat offline (banner E5) → online → "Coba lagi" → tugas sampai di server palsu dengan `user_id` akun. Lulus.
- RLS dua akun (`supabase/tests/rls_dua_akun.sql`) di proyek dev `superapp-dev`: LULUS.
- Belum: uji integrasi di HP asli dengan Supabase dev (butuh email OTP aktif), dan pemakaian sehari penuh.
