# Peta navigasi & rute (MVP)

Semua layar MVP, rute `go_router`-nya, tombol yang membukanya, dan ke mana layar itu kembali. Claude Code membuat rute persis seperti tabel ini; layar atau rute yang tidak ada di sini belum dibuat.

## Alur saat app dibuka

1. **Splash (00)** — splash native Android, lalu app memeriksa sesi.
2. **Belum pernah login** → Intro (00a–00d). Tombol "Mulai sekarang" di 00d membuka Masuk dengan email → Masukkan kode (6 digit dari email). Kalau 00a–00c belum dibuat, intro langsung mulai dari 00d.
3. **Login pertama berhasil** → Setup awal 01a → 01b → 01c → Beranda. "Lewati" di langkah mana pun langsung ke Beranda.
4. **Sudah login** → Kunci sidik jari (01) → Beranda. Sidik jari gagal 3 kali atau "Pakai PIN" → Masukkan PIN (H06).
5. **Sesi berakhir** (token tidak bisa diperbarui) → G1, tombol "Masuk lagi" membuka Masuk dengan email; data di HP tetap ada.

## Rute

Lima tab Bottom Nav memakai `StatefulShellRoute.indexedStack` supaya posisi gulir dan filter tiap tab tetap saat berpindah tab.

| Rute | Layar | Dibuka dari | Bottom nav |
| --- | --- | --- | --- |
| `/intro` | 00a–00d Intro (satu halaman bergeser) | Pembukaan pertama | Tidak |
| `/masuk` | Masuk dengan email — **belum ada frame Figma (F-12), jangan dibuat dulu** | 00d › Mulai sekarang; G1 › Masuk lagi | Tidak |
| `/masuk/kode` | Masukkan kode verifikasi — **belum ada frame Figma (F-12), jangan dibuat dulu** | `/masuk` › kirim kode | Tidak |
| `/kunci` | 01 Kunci sidik jari | Setiap app dibuka dari keadaan tertutup | Tidak |
| `/kunci/pin` | H06 Masukkan PIN | 01 › Pakai PIN | Tidak |
| `/setup/jadwal` | 01a Jadwal semester | Setelah login pertama | Tidak |
| `/setup/dompet` | 01b Dompet & saldo awal | 01a › Lanjut | Tidak |
| `/setup/keamanan` | 01c Keamanan | 01b › Lanjut | Tidak |
| `/beranda` | 02 Beranda (E1 kalau belum ada data) | Tab Beranda | Ya |
| `/tugas` | 03 Tugas (E2 kalau kosong) | Tab Tugas; Beranda › Lihat semua | Ya |
| `/tugas/baru` | 15 Tugas baru | 03 › FAB; E2 › Tambah tugas; checklist E1 | Tidak |
| `/tugas/cari` | H04 Pencarian | 03 › ikon Search | Tidak |
| `/tugas/:id` | 16 Detail tugas | Ketuk Task Item di 02, 03, atau 20 | Tidak |
| `/tugas/:id/edit` | H01 Edit tugas | 16 › ikon Edit | Tidak |
| `/kuliah` | 04 Kuliah (K1 kalau kosong) | Tab Kuliah | Ya |
| `/kuliah/jadwal-baru` | H02 Jadwal baru | 04 › ikon +; K1; checklist E1 | Tidak |
| `/kuliah/:id` | 20 Detail mata kuliah (MVP) | Ketuk Class Item di 04; kartu Kelas berikutnya di 02 | Tidak |
| `/kuliah/:id/edit` | H02 dalam mode ubah | 20 › ikon Edit | Tidak |
| `/keuangan` | 05 Keuangan (E3 kalau belum ada dompet) | Tab Keuangan; Beranda › Lihat semua | Ya |
| `/keuangan/transaksi-baru` | 17 Transaksi baru | 05 › FAB; checklist E1 | Tidak |
| `/keuangan/transaksi/:id` | H11 Ubah transaksi | Ketuk Transaction Item di 02 atau 05 | Tidak |
| `/lainnya` | 06 Lainnya (MVP) | Tab Lainnya | Ya |
| `/pengaturan` | 14 Pengaturan | Avatar di 02; ikon User di 06 | Tidak |
| `/pengaturan/pin` | H05 Atur PIN cadangan | 14 › PIN cadangan; 01c › PIN cadangan | Tidak |
| `/katalog` | Katalog komponen `core/ui` — **hanya build debug**, tidak ada di rilis (disetujui Bayu, W1-09) | Daftar "Rute debug" di tab Lainnya (debug) | Tidak |

Status W1-09: semua rute di atas sudah ada dengan layar sementara berjudul, kecuali `/masuk` dan `/masuk/kode` (menunggu desain F-12). Pengalihan saat app dibuka (cek sesi → Intro/Kunci/Beranda) dibuat di W1-10; sampai saat itu app langsung membuka `/beranda`.

## Pop-up (bukan rute)

Bottom sheet dibuka dengan `showModalBottomSheet` memakai Overlay Header dari `core/ui`. Pilihan bertingkat mengganti sheet sebelumnya, tidak menumpuk.

| Kode | Pop-up | Dibuka dari |
| --- | --- | --- |
| P01 | Pilih tanggal | 15 › Tanggal; 17 › Tanggal |
| P02 | Pilih jam | 15 › Jam; 17 › Jam |
| P03 | Pilih mata kuliah | 15 › Mata kuliah |
| P05 | Konfirmasi hapus | 16 › Hapus (pola yang sama untuk hapus lainnya) |
| P06 | Pilih dompet | 17 › Dompet |
| P07 | Dompet baru | P06 › + Tambah dompet |
| P20 | Pilih semester | 01a › Semester; H02 › Semester |
| P37 | Akun | 14 › kartu akun |
| P38 | Keluar akun | P37 › Keluar dari akun |
| P47 | Hapus transaksi | H11 › ikon Hapus (kanan atas) |

P04 Ingatkan saya tidak dipakai di MVP. Snackbar (E4) dan banner (E5, G8) bukan rute; keduanya ditampilkan dari layar yang sedang terbuka.

## Aturan kembali

- Tombol Back Android dan panah kiri di Top App Bar kembali ke layar sebelumnya.
- Ikon Close di form baru (15, 17) menutup form tanpa menyimpan.
- Setelah "Simpan", form tertutup dan kembali ke layar asal; data baru langsung tampil.
- Di tab selain Beranda, Back pindah ke tab Beranda. Di Beranda, Back keluar dari app.
- Setelah hapus dari 16 Detail tugas, kembali ke daftar dan tampilkan snackbar Urungkan. Sama untuk hapus transaksi dari H11: kembali ke 05 dengan snackbar Urungkan.
- Halaman Kunci, Setup, Intro, dan Masuk tidak bisa dikembalikan dengan Back setelah dilewati. Dari Masukkan kode, Back kembali ke Masuk dengan email (untuk mengganti alamat).

## Celah desain yang belum ada frame-nya

Claude Code tidak mengarang bagian ini. Kalau sampai ke sini, berhenti dan tanya Bayu.

| Kebutuhan | Kenapa perlu | Usulan sementara |
| --- | --- | --- |
| Keluar form yang sudah diisi | Ikon Close bisa membuang isian tanpa sengaja | Tutup langsung seperti sekarang, atau tambah konfirmasi; perlu keputusan |
| Layar masuk email dan kode (F-12) | Login diganti dari Google ke email + kode verifikasi (keputusan Bayu, 19 Nov 2026) | Bayu mendesain di Figma dulu; termasuk kode salah, kedaluwarsa, kirim ulang, dan memuat |
| Nama pengguna (F-14) | Login email tidak memberi nama, padahal 01 dan G1 menyapa "Halo, Bayu" | Perlu keputusan: kolom Nama di layar masuk atau di setup awal |
| Isi 14 Pengaturan versi MVP | Frame 14 berisi baris untuk fitur Tahap 2–3 (notifikasi, Data) | Tampilkan hanya kartu akun dan grup keamanan; baris lain disembunyikan |
