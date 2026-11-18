# PRD — Super App (MVP)

Dokumen ini menetapkan apa yang dibangun di MVP dan kapan sebuah fitur dianggap selesai. Acuan tampilannya file Figma [Super App](https://www.figma.com/design/kK09B05WOCxXSf5dvukX41); detail teknis ada di `spesifikasi-teknis.md`.

## Masalah & tujuan

Jadwal kuliah, tugas, dan keuangan tersebar di banyak tempat: grup chat, kalender, catatan, dan ingatan. Super App menyatukannya dalam satu app yang tetap jalan tanpa internet dan tersinkron ke cloud.

Tujuan MVP:

- Semua tugas dan jadwal kuliah semester ini tercatat di satu tempat.
- Satu transaksi bisa dicatat dalam kurang dari 10 detik.
- Beranda menjawab "apa yang harus aku kerjakan hari ini" tanpa membuka modul lain.

Ukuran berhasil: app dipakai setiap hari selama 2 minggu setelah rilis MVP, dan tidak ada data yang hilang saat HP offline lalu online lagi.

## Pengguna

- **Utama:** Bayu — mahasiswa Informatika, memakai HP Android dan laptop Windows.
- **Setelah MVP:** teman kuliah lewat kode undangan, masing-masing dengan data terpisah.

## Ruang lingkup MVP (Android)

| Area | Masuk MVP | Layar Figma |
| --- | --- | --- |
| Akun & keamanan | Login Google, kunci sidik jari dengan PIN cadangan, setup awal 3 langkah (bisa dilewati) | 01, 01a–01c, H05, H06 |
| Beranda | Kelas berikutnya, tugas hari ini dan terlambat, saldo, checklist "Siapkan Super App kamu" | 02, E1 |
| Tugas | Tambah, ubah, hapus, tandai selesai, sub-tugas, prioritas, mata kuliah, filter per deadline | 03, 15, 16, H01, E2 |
| Kuliah | Semester, jadwal mingguan, mata kuliah + dosen + ruang, detail mata kuliah | 04, 20 (MVP), H02, K1 |
| Keuangan | Transaksi masuk/keluar, kategori, dompet dan saldo, ringkasan bulan ini, ubah/hapus transaksi | 05, 17, H11, P47, E3 |
| Lainnya & Pengaturan | Grid modul (yang belum dibuat disembunyikan), akun, keamanan, keluar | 06 (MVP), 14, P37, P38 |
| Status | Kosong, memuat, offline, gagal simpan, isian belum lengkap, urungkan, sesi berakhir | E4, E5, E7, G1–G3, G8 |

Splash (00) dan ikon app juga masuk MVP. Intro 00a–00d boleh menyusul.

## Di luar MVP

- **Tahap 2:** versi desktop, notifikasi, Kebiasaan, Catatan, Kalender, batas absen, tambah cepat, Materi, scan ke PDF, lampiran file di tugas.
- **Tahap 3:** Fokus, Skripsi, Belajar, Proyek, Statistik, Nilai & IPK, budget, tagihan, Tabungan, Patungan, review mingguan, KKN.
- **Tidak dibuat:** fitur AI apa pun (dihapus dari rencana 19 Nov 2026).
- **Nanti:** widget layar utama, ekspor, bagikan dari app lain, akun teman dan landing page.

## User story & kriteria selesai

### Akun & keamanan

**Sebagai pengguna, aku masuk dengan akun Google supaya dataku tersimpan di cloud.**

- [ ] Login Google membuat profil di Supabase; login berikutnya langsung ke Beranda.
- [ ] Setelah login pertama, setup awal (jadwal semester, dompet & saldo awal, keamanan) tampil dan bisa dilewati.
- [ ] Sesi yang berakhir menampilkan G1 dengan tombol Masuk lagi; data di HP tidak hilang.

**Sebagai pengguna, aku membuka app dengan sidik jari supaya data keuanganku aman.**

- [ ] App meminta sidik jari setiap dibuka dari keadaan tertutup.
- [ ] PIN cadangan bisa dipakai saat sidik jari gagal atau tidak tersedia.

### Tugas

**Sebagai mahasiswa, aku mencatat tugas dengan deadline dan mata kuliahnya supaya tidak ada yang terlewat.**

- [ ] Judul wajib; deadline, mata kuliah, prioritas, catatan, dan sub-tugas opsional.
- [ ] Isian yang belum lengkap menampilkan pesan di kolomnya (G2), dan isian lain tidak hilang.
- [ ] Daftar bisa disaring per deadline sesuai layar 03; tugas lewat deadline ditandai merah.
- [ ] Tandai selesai dan hapus bisa diurungkan lewat snackbar (E4).

### Kuliah

**Sebagai mahasiswa, aku melihat jadwal kelas minggu ini dan detail tiap mata kuliah.**

- [ ] Jadwal tampil per hari; jadwal baru ditambah lewat halaman H02.
- [ ] Detail mata kuliah menampilkan dosen, ruang, jadwal, dan tugas yang terkait.
- [ ] Semester belum ada isinya menampilkan K1.

### Keuangan

**Sebagai mahasiswa, aku mencatat pengeluaran dengan cepat supaya tahu sisa uang bulan ini.**

- [ ] Form transaksi cukup nominal, kategori, dan dompet; tanggal otomatis hari ini.
- [ ] Saldo dompet dan ringkasan bulan ini (masuk, keluar, sisa) langsung berubah.
- [ ] Transaksi yang dihapus bisa diurungkan.

### Beranda

**Sebagai pengguna, aku melihat semua yang penting hari ini di satu layar.**

- [ ] Menampilkan kelas berikutnya, tugas jatuh tempo hari ini dan yang terlambat, serta total saldo.
- [ ] Akun baru tanpa data menampilkan E1 dengan checklist Siapkan Super App.

### Sinkron & offline

**Sebagai pengguna, aku tetap bisa mencatat tanpa internet.**

- [ ] Tambah, ubah, dan hapus berjalan tanpa internet dan tersimpan di HP.
- [ ] Banner offline (E5) tampil selama tidak ada internet.
- [ ] Saat online lagi, perubahan terkirim otomatis; kalau gagal lebih lama, tampil G8 dengan tombol Coba lagi.

## Kebutuhan non-fungsional

- **Tampilan:** sama dengan frame Figma, hanya mode gelap.
- **Bahasa & format:** Bahasa Indonesia; uang Rp1.250.000; tanggal "Jumat, 6 Nov"; jam 24 jam dengan titik (08.00).
- **Kecepatan:** Beranda tampil kurang dari 2 detik setelah sidik jari, karena data dibaca dari HP.
- **Keamanan:** data tiap akun dilindungi Row Level Security; app hanya memegang kunci publik Supabase.
- **Data:** tidak ada hapus permanen di MVP; hapus berarti ditandai dan bisa diurungkan.

## Urutan pengerjaan

Tidak ada tenggat; MVP dikerjakan berurutan per fase sampai selesai. Rincian tugas ada di `backlog.md`.

| Fase | Selesai di akhir fase |
| --- | --- |
| 1 — fondasi | Proyek Flutter, token tema dan komponen `core/ui` dari Figma, proyek Supabase dev, database drift, login Google, kunci sidik jari + PIN |
| 2 — Tugas & Kuliah | Modul Tugas dan Kuliah, termasuk tampilan kosong dan isian belum lengkap |
| 3 — Keuangan, Beranda, sinkron | Modul Keuangan, Beranda, sinkron offline dan banner offline |
| 4 — pertama kali, rapikan, rilis | Setup awal, splash dan ikon app, tampilan gagal, Lainnya dan Pengaturan, uji, build APK release |

Setelah MVP terpasang, app dipakai 1–2 minggu sambil mencatat bug sebelum Tahap 2 dimulai.

Kalau ingin memakai app lebih cepat, yang paling aman ditunda: setup awal (cukup langsung ke Beranda kosong) dan PIN cadangan; sidik jari, sinkron, dan empat modul inti tetap wajib.
