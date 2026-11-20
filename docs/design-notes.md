# Catatan desain untuk Claude Code

Penjelasan per bagian file Figma Super App, supaya Claude Code membangun persis seperti desain dan tidak salah tafsir. `CLAUDE.md` merujuk ke file ini. Kalau sesuatu tidak tercakup di sini dan tidak jelas di Figma, **tanya dulu, jangan menebak**.

Node id tiap frame ada di `figma-frames.md`. Token ada di `design-tokens.md`.

## 1. Cara membaca file Figma

| Halaman | Isi | Cara memakainya |
| --- | --- | --- |
| Foundations (0:1) | Warna, 13 gaya teks, spasi, sudut | Satu-satunya sumber token di `core/theme` |
| Components (4:2) | Komponen dan semua variannya | Satu komponen Figma = satu widget di `core/ui`; varian = parameter widget |
| Screens — Mobile (4:3) | Layar HP 412×917 | Nama frame berawalan kode, misalnya "03 Tugas" |
| Screens — Desktop (34:2) | Layar 1440×900 | Tahap 2, belum dikerjakan |
| Pop-up & Input (50:180) | Bottom sheet P, halaman penuh H, dialog desktop DP | Label di atas tiap frame ("Dari: …") menyebut tombol yang membukanya |
| Landing Page (161:2) | Situs unduhan | Bukan bagian app Flutter. Dibangun sebagai HTML/CSS statis di `website/` (lihat `pengembangan.md`); frame-nya di `figma-frames.md` |

- Frame specimen di halaman Components hanya peraga. Yang dibangun adalah komponennya, bukan kotak peraga, label abu, atau teks penjelasannya.
- Semua isi layar adalah **data contoh**: nama "Bayu", mata kuliah, dosen, nominal, tanggal Jumat 6 Nov 2026, jam 07.35. Di kode semuanya diambil dari database atau jam HP; jangan pernah ditulis langsung.
- Teks label tetap (judul layar, nama kolom, isi tombol, pesan kosong dan gagal) disalin persis dari Figma.
- Tidak ada fitur AI di app. Kalau menemukan sisa elemen AI di Figma (ikon sparkle, "Tanya AI", "Dibaca AI"), jangan dibangun dan laporkan.

## 2. Yang tidak ikut dibangun

- **Status Bar** (jam, sinyal, baterai) di atas setiap layar adalah gambar status bar Android. Jangan dibuat sebagai widget; cukup atur ikon status bar sistem jadi terang di atas latar hitam dan hormati safe area.
- Dialog sistem: sidik jari OS, pemilih file, kamera, dan layar scan ML Kit. Pakai bawaan sistem atau paketnya. (Login tidak lagi memakai dialog pilih akun Google; diganti layar masuk email + kode, lihat `catatan-figma.md` F-12.)
- Teks dan kotak penjelasan di samping frame (misalnya "Catatan untuk dibuat" di papan widget).

## 3. Fondasi

- Token warna, teks, spasi, dan sudut ada di `design-tokens.md`. Tidak ada warna atau ukuran lain.
- **Hanya mode gelap.** `ThemeData` dibuat sendiri dari token; jangan memakai warna bawaan Material (ungu, abu Material, bayangan, efek ripple berwarna).
- **Label** (Label/Large, Medium, Small) tampil kapital. Simpan teksnya dalam huruf biasa dan ubah ke kapital di widget.
- **Doto** hanya untuk angka besar (Display). Titik ribuan di Doto tampak seperti "+" kecil; itu sifat font-nya. Tetap pakai Doto sampai Bayu memutuskan lain.
- **Gradient/Branding** (pasir → oranye → merah) hanya dipakai di tempat yang ada di Figma, misalnya kartu Total saldo di Keuangan.
- **Ikon:** ekspor SVG dari Components [01] (24px, garis 1,5, ujung kotak). Jangan mengganti dengan Material Icons atau Cupertino Icons, meski bentuknya mirip.
- Font dipasang sebagai aset di `assets/fonts`, bukan lewat google_fonts saat jalan.

## 4. Komponen

| Komponen Figma | Varian | Catatan penting |
| --- | --- | --- |
| Button | Primary, Ghost, Danger × Default, Hover, Pressed, Disabled | Sudut 12, label Geist Mono kapital. Hover hanya di desktop. Danger hanya untuk hapus dan keluar akun |
| FAB | — | 56×56, oranye, ikon Plus hitam. Hanya di layar yang punya FAB di Figma |
| Input | Default, Focus, Filled, Error | Label kecil kapital di atas kolom. Focus: garis dan label oranye, kursor oranye. Filled: teks ketikan putih. Error: garis dan pesan merah di bawah kolom. Disabled tampil seperti Default |
| Checkbox | Unchecked, Checked | Kotak bersudut kecil; dicentang = isi oranye, centang hitam |
| Switch | Off, On | On = oranye |
| Chip | Default, Selected | Bentuk pil, untuk filter dan pilihan; Selected = isi oranye, teks hitam |
| Badge | Neutral, Success, Warning, Danger | Terlambat = Danger, Hari ini = Warning, Selesai dan Lunas = Success, Besok dan "3 hari" = Neutral |
| Card, Stat Card | — | Latar Surface/Raised, garis Dark Gray, sudut 20. Angka Stat Card memakai Doto |
| Progress Bar | Value 0–100 | Varian per 10 hanya peraga; di kode nilainya bebas 0–100 |
| Nav Item, Bottom Nav | Default, Active | 5 tab: Beranda, Tugas, Kuliah, Keuangan, Lainnya. Aktif: ikon dan label oranye + garis pendek oranye di atas ikon |
| Top App Bar | — | Untuk form dan detail: ikon Close (form baru) atau Arrow Left (detail), judul, ikon aksi di kanan |
| Section Header | — | Judul kiri + tautan oranye kapital "Lihat semua →" di kanan |
| Task Item | Default, Done | Checkbox, judul, baris meta "Mata kuliah · jam", Badge di kanan. Done: checkbox oranye, judul abu |
| Transaction Item | Expense, Income | Kotak ikon panah, judul, meta kapital "TUNAI · MAKAN · 07.10". Expense: −Rp putih; Income: +Rp hijau |
| Class Item | Upcoming, Now, Done | Kolom jam di kiri. Now: garis oranye + badge "Sedang berlangsung" |
| Day Pill | Default, Selected | Hari singkat + tanggal; Selected = isi oranye |
| Wallet Card | — | Nama dompet kapital + saldo |
| Module Tile | Default, Segera | Kotak ikon 40 + judul + caption. Segera (MVP, F-66): ikon dan judul Gray, Badge Neutral "Segera" menggantikan caption, tidak bisa diketuk |
| Segmented Control | First, Second | Dua pilihan, misalnya Pengeluaran / Pemasukan |
| Select, List Row, Checklist Item | Select: Filled, Empty, Disabled, Error | Select membuka bottom sheet pilihan, bukan dropdown Material. Disabled = nilai "—" abu, tidak bisa diketuk |
| Action Bar | Single, Double | Bar tombol di bawah form dan detail. Double: kiri Ghost, kanan Primary |
| Overlay Header, Option Item | Sheet, Dialog; Default, Selected | Bottom sheet: sudut atas 20, handle, scrim hitam 70%, lebar penuh |
| Date Picker, Time Picker, Keypad, Text Area | — | Dibangun sendiri sesuai Figma; jangan pakai showDatePicker atau showTimePicker Material |
| Page Indicator | Page 1–4 | Titik aktif memanjang oranye, lainnya titik abu |
| Snackbar | — | Muncul 4 detik di atas bottom nav, teks + aksi "Urungkan". 20 dari tepi, 12 di atas Bottom Nav; FAB 16 di atas snackbar |
| Icon Button | Icon (swap) | Tombol ikon bulat 40 di kanan atas menu utama (Cari, Notifikasi, Tambah jadwal, Akun). Ditambahkan 20 Nov 2026 (F-22) |
| Bottom Sheet | Footer on/off | Kerangka semua pop-up P: Overlay Header, isi, footer tombol. Ditambahkan 20 Nov 2026 (F-27) |
| Banner | Warning, Danger, Info, Success | Keadaan yang bertahan (offline, sinkron gagal); di bawah header, di atas isi |

Komponen Habit Item, Note Card, Project Card, Step Item, Bill Item, Budget Item, File Item, Folder Card, dan komponen desktop dibangun saat modulnya dikerjakan.

## 5. Aturan umum layar HP

- **Menu utama** (02–06): label kecil kapital (tanggal atau ringkasan) di atas judul Heading/Large, tombol ikon bulat di kanan, Bottom Nav di bawah.
- **Form dan detail** (15–17, 20, H): tanpa Bottom Nav; Top App Bar di atas dan Action Bar di bawah.
- **Input singkat** = bottom sheet (P), **input panjang** = halaman penuh (H). Pilihan bertingkat mengganti sheet sebelumnya, tidak bertumpuk. Konfirmasi hapus dan keluar memakai tombol Danger dan tanpa tombol tutup.
- **Ukuran layar:** 412×917 hanya acuan. Lebar mengikuti HP; jangan mengunci lebar 412. Jarak tepi, celah antarkartu, dan ukuran elemen diambil dari get_design_context.
- **Teks lebih panjang dari contoh:** judul maksimal 2 baris dan meta 1 baris, lalu dipotong dengan elipsis, kecuali Figma menunjukkan lain.
- **Format:** uang Rp1.250.000; ringkasan pendek Rp1,25jt dan Rp340rb; pengeluaran −Rp15.000, pemasukan +Rp1.500.000; tanggal "Jumat, 6 November" (kapital di label); jam 08.00–09.40.

## 6. Layar MVP

### 00 Splash, 00a–00d Intro

- Splash: logo S oranye di tengah dengan cahaya oranye, teks "Super App" di bawah. Pakai splash native Android dengan gambar yang sama, lalu langsung ke layar berikutnya.
- Intro (boleh menyusul): 4 halaman, tampil sekali sebelum login. Halaman 1–3 punya "Lewati"; ilustrasi dari komponen app di atas cincin titik oranye.

### 01 Kunci sidik jari

- "Halo, Bayu" memakai Doto dan nama dari profil. Ikon sidik jari di tengah cincin titik oranye, teks status di bawahnya.
- Prompt sidik jari dari sistem (local_auth) langsung muncul; gambar di layar hanya latar.
- Tombol Ghost "Pakai PIN" di bawah membuka PIN cadangan (H06). Baris kecil status sinkron di paling bawah ("Tersinkron" atau "Belum tersinkron sejak 08.12").
- Tanpa nama (nama dikosongkan di 00g): "Halo" satu baris.

### 01a–01c Setup awal

- 3 langkah dengan progress bar di atas, label "Langkah 1 dari 3", dan "Lewati" di kanan.
- 01a jadwal semester (Select semester, daftar mata kuliah, "+ Tambah mata kuliah"); 01b dompet dan saldo awal (Tunai, Bank, E-wallet, "+ Dompet lain", total saldo); 01c keamanan (sidik jari, PIN cadangan).
- Tombol terakhir "Selesai, ke Beranda →".

### 02 Beranda

- Kartu oranye "Kelas berikutnya" dengan hitung mundur dan panah; isinya dari jadwal hari ini. Kalau tidak ada kelas lagi hari ini, kartu disembunyikan.
- Dua Stat Card: Tugas aktif dan Saldo (format pendek).
- Bagian "Tugas hari ini" (Task Item, termasuk yang terlambat) dan "Transaksi terakhir" (2 terbaru), masing-masing dengan "Lihat semua →" ke tab terkait.
- Avatar (huruf awal nama di lingkaran oranye) membuka Pengaturan. Layar 02 tidak punya FAB.

### 03 Tugas

- Label atas "5 aktif · 2 hari ini" dihitung dari data. Chip filter: Semua, Hari ini, Minggu ini, Selesai.
- Tugas dikelompokkan: Hari ini (dengan tanggal), Besok, Minggu ini, Selesai. Kelompok kosong tidak ditampilkan.
- Ketuk checkbox = tandai selesai + snackbar Urungkan. Ketuk baris = Detail tugas (16). FAB = Tugas baru (15). Ikon Search membuka pencarian (H04).

### 04 Kuliah

- Label atas "Semester 7 · Minggu ke-10" dari semester aktif. Day Pill sesuai hari yang ada di Figma, hari ini terpilih otomatis.
- Jadwal hari terpilih: Class Item dengan status Upcoming, Now, atau Done menurut jam sekarang, jumlah kelas di kanan judul hari.
- Ikon + di kanan atas membuka Jadwal baru (H02).

### 05 Keuangan

- Kartu Total saldo: angka Doto, baris Masuk (hijau) dan Keluar (merah) bulan ini, gradien hanya di sisi kanan kartu seperti Figma.
- Wallet Card per dompet, lalu "Transaksi terakhir". FAB = Transaksi baru (17).

### 06 Lainnya dan 14 Pengaturan

- Lainnya: grid Module Tile. Di MVP semua modul tampil sebagai Module Tile keadaan Segera (ikon dan judul Gray, Badge Neutral "Segera", tidak bisa diketuk) dan label jumlah modul disembunyikan (frame "06 Lainnya (MVP, modul segera)" 257:6514, F-66). Saat modul selesai, tile-nya berganti ke keadaan normal. Ikon User di kanan atas membuka Pengaturan (sama dengan avatar di Beranda).
- Pengaturan: daftar List Row; tanpa pilihan tema. Di MVP tampilkan hanya kartu akun dan grup keamanan (lihat `navigasi.md`).

### 15 Tugas baru, H01 Edit tugas

- Top App Bar dengan Close dan judul "Tugas baru". Kolom: Judul tugas, Mata kuliah (Select), Tanggal + Jam, Prioritas (chip Rendah, Sedang, Tinggi), Sub-tugas (Checklist Item + "+ Tambah sub-tugas"), Catatan.
- Action Bar Single "Simpan tugas". Judul kosong = Input Error (G2), isian lain tetap.

### 16 Detail tugas

- Badge status dan prioritas di atas judul, baris meta (tanggal, mata kuliah), Sub-tugas dengan progress "2/4 selesai", kartu Catatan.
- Ikon Edit membuka H01. Action Bar Double: "Hapus" (Ghost) dan "Tandai selesai" (Primary).

### 17 Transaksi baru, H11 Ubah transaksi

- Segmented Control Pengeluaran / Pemasukan, Nominal dengan angka Doto dan garis oranye, chip Kategori, Select Dompet, Tanggal ("Hari ini") + Jam, Catatan. Action Bar "Simpan transaksi".
- Keyboard angka langsung terbuka di kolom Nominal.
- Ketuk Transaction Item membuka H11: form yang sama berisi data, judul "Ubah transaksi", ikon Hapus di kanan atas (membuka P47), Action Bar "Batal" + "Simpan perubahan".

### 20 Detail mata kuliah

- Label "3 SKS · Semester 7", nama mata kuliah, baris dosen, jadwal, dan ruang, ikon Edit di kanan atas.
- Di MVP ikuti frame "20 Detail Mata Kuliah (MVP)": di bawah info langsung label "Tugas aktif · n" dan Task Item tugas mata kuliah itu (ketuk = Detail tugas). Kehadiran dan Pertemuan menyusul di Tahap 2.

### Tampilan kosong, status, dan gagal

- E1 Beranda kosong: kartu "Siapkan Super App kamu" dengan progress dan 3 checklist (isi jadwal, tambah tugas pertama, catat transaksi pertama); hilang setelah ketiganya selesai.
- E2, E3, K1: ikon oranye dalam lingkaran, judul "Belum ada …", satu kalimat, satu tombol, persis seperti frame-nya.
- E4 snackbar Urungkan, E5 banner offline, E7 memuat (kotak abu di posisi isi), G1 sesi berakhir, G2 isian belum lengkap, G3 gagal menyimpan, G8 sinkron gagal. Ikuti frame masing-masing; pesan menyebut apa yang terjadi, apa yang tetap aman, dan satu tombol lanjut.

## 7. Elemen tahap berikutnya di layar MVP

Beberapa layar MVP sudah menggambar elemen dari modul Tahap 2–3. Selama modulnya belum ada, elemen itu **disembunyikan utuh**: blok dan jaraknya hilang, elemen lain tidak digeser ke tempatnya, dan tidak ada teks "Segera hadir" atau pengganti lain.

| Layar | Elemen | Di MVP |
| --- | --- | --- |
| 01c Setup keamanan | Grup "Pengingat" (kelas, deadline, tagihan) | Sembunyikan; muncul saat notifikasi dibuat (Tahap 2) |
| 02 Beranda | Ikon lonceng Notifikasi | Sembunyikan |
| 04 Kuliah | Ikon Materi; bagian "Catatan terakhir" | Sembunyikan |
| 05 Keuangan | Chip Tagihan dan Budget; bagian "Tagihan terdekat"; ikon Statistik | Sembunyikan; baris chip hilang karena tinggal Ringkasan |
| 15 Tugas baru | Baris "Ingatkan saya" | Sembunyikan |
| H02 Jadwal baru | Baris "Ulangi tiap minggu · 16 pertemuan" (butuh fitur pertemuan) | Sembunyikan (F-38) |
| P07 Dompet baru | Baris "Hitung di total saldo" (model dompet belum punya kolomnya) | Sembunyikan (F-43) |
| 16 Detail tugas | Baris pengingat; bagian Lampiran (Scan PDF, Pilih file) | Sembunyikan |
| 20 Detail mata kuliah | Kartu Kehadiran; tab Pertemuan | Sembunyikan Stat Card, Segmented Control, daftar Pertemuan, dan FAB; tampilkan label "Tugas aktif · n" + Task Item mata kuliah itu. Acuan: frame "20 Detail Mata Kuliah (MVP)" |
| 06 Lainnya | 10 Module Tile (semua modul Tahap 2–3) | Tampilkan tile keadaan Segera (tidak bisa diketuk) dan sembunyikan label jumlah modul; tile berganti ke keadaan normal saat modulnya selesai. Acuan: frame "06 Lainnya (MVP, modul segera)" 257:6514 (F-66) |
| 14 Pengaturan | Grup Notifikasi, Data | Tampilkan hanya kartu akun dan grup keamanan |

Bentuk MVP layar 06 dan 20 ada di section "MVP · layar yang disederhanakan (06, 20)" di halaman Screens — Mobile. Untuk layar itu, frame MVP yang diikuti, bukan frame aslinya.

## 8. Kesalahan yang sering terjadi

- [ ] Memakai widget Material bawaan (AppBar, TextField, Checkbox, Switch, DatePicker, SnackBar) dengan tampilan bawaannya, bukan komponen `core/ui`.
- [ ] Bayangan, elevasi, atau ripple berwarna yang tidak ada di Figma.
- [ ] Menulis data contoh dari Figma langsung di kode.
- [ ] Menggambar status bar palsu atau mengunci lebar 412.
- [ ] Mengganti ikon dengan Material Icons.
- [ ] Font diunduh saat jalan, atau Doto dipakai untuk teks biasa.
- [ ] Label tombol dan kolom tidak kapital, atau letter spacing-nya hilang.
- [ ] Menambah layar, tombol, animasi, atau teks yang tidak ada di Figma (kecuali gerak di §9).
- [ ] Lupa keadaan kosong, memuat, dan gagal pada layar yang punya frame-nya.

## 9. Gerak (animasi)

Figma belum punya animasi. Bayu menyetujui pengecualian ini (21 Nov 2026); nilainya di `lib/core/theme/app_motion.dart` (`AppMotion`) dan tidak dibuat ulang per layar:

| Saat | Gerak | Di kode |
| --- | --- | --- |
| App dibuka | Splash native (hitam) memudar ke layar pertama, 300 ms | `AppFadeIn` di `lib/app/app.dart` |
| Membuka atau menutup layar penuh (form, detail, pengaturan, intro → masuk) | Layar baru bergeser 6% dari kanan sambil memudar, 250 ms; layar di bawahnya diam | `AppPageTransitionsBuilder` di tema |
| Pindah tab Bottom Nav | Isi tab memudar masuk, 200 ms; posisi gulir tab tetap | `AppFadeIn` di `_TabShell` (`router.dart`) |

Semua memakai kurva `easeOutCubic` dan mati kalau "Hapus animasi" di pengaturan HP aktif. Geser antarhalaman intro (00a–00d) bawaan `PageView`. Pop-up bawah memakai animasi bawaan bottom sheet. Gerak baru di luar tabel ini tetap harus didesain di Figma dulu atau ditanyakan ke Bayu.
