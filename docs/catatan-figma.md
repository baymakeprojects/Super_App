# Catatan perbaikan Figma

Daftar bagian desain Figma yang **salah, kurang, tidak konsisten, atau tidak ada**, ditemukan saat mengerjakan tugas backlog. Tujuannya supaya Bayu bisa memperbaiki atau melengkapi Figma nanti, lalu kodenya diselaraskan.

## Cara memakai

- Claude Code menambah baris di sini setiap kali menemukan masalah desain saat mengerjakan tugas, termasuk yang sudah diputuskan Bayu untuk sementara.
- Kalau masalahnya memengaruhi kode yang sedang dibuat, tetap **tanya Bayu dulu** (aturan `CLAUDE.md`). Catatan ini bukan pengganti bertanya.
- **Jenis:** `Salah` (desain keliru) · `Kurang` (ada, tapi belum lengkap) · `Tidak ada` (belum didesain sama sekali) · `Tidak konsisten` (bertentangan dengan aturan atau desain lain).
- **Status:**
  - `Terbuka`: belum diubah di Figma.
  - `Diubah di Figma`: Bayu sudah memperbaiki Figma, tapi kode belum diselaraskan.
  - `Selesai`: Figma dan kode sudah sama.
  - `Tidak diubah`: Bayu memutuskan Figma dibiarkan seperti sekarang.
- Setelah Figma diubah, ganti statusnya jadi `Diubah di Figma`. Tugas berikutnya yang menyentuh bagian itu akan menyelaraskan kode, lalu mengubahnya jadi `Selesai`.

## Daftar

| No | Tugas | Bagian Figma (node) | Jenis | Masalah | Sementara di kode | Usulan perubahan Figma | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| F-01 | W1-03 | Foundations › [03] Spasi & sudut › Radius Scale (4:215) | Kurang | Variabel `Radius/Item` = 16 ada dan dipakai di Components [06], tapi tidak dipajang di halaman Foundations, dan tidak disebut di teks "input 10, tombol 12, kartu 20". | `AppRadius.item = 16` dibuat dari variabelnya. | Tambah kotak "Item · 16" di Radius Scale dan sebut di teks penjelasan. | Terbuka |
| F-02 | W1-04 | Components › [01] Ikon › Icon/Menu (5:16), Icon/Close (5:21) | Tidak konsisten | Aturan ikon "stroke 1.5, ujung kotak", tapi Menu memakai stroke 2 dengan ujung bulat, dan Close memakai ujung bulat. | Dipakai apa adanya (keputusan Bayu). | Samakan Menu dan Close jadi stroke 1.5 ujung kotak, lalu ekspor ulang `assets/icons/menu.svg` dan `close.svg`. | Terbuka |
| F-03 | W1-04 | Components › [01] Ikon › teks penjelasan (5:10) | Salah | Teks menyebut "22 ikon baru", padahal ada 26 ikon baru (total 39). | Tidak berpengaruh ke kode. | Ubah teks jadi "26 ikon baru". | Terbuka |
| F-04 | W1-05 | Components › [02] Tombol › Button Style=Danger (49:360) | Kurang | Danger hanya punya State=Default; Hover, Pressed, dan Disabled belum ada (Primary dan Ghost sudah lengkap). | Danger tidak berubah tampilan saat hover, ditekan, atau nonaktif (keputusan Bayu). | Tambah varian Danger × Hover, Pressed, Disabled. | Terbuka |
| F-05 | W1-05 | Components › [03] Form › Input (6:51) | Tidak ada | Teks hasil ketikan dan kursor tidak didesain; yang ada hanya placeholder abu. Keadaan Disabled juga tidak ada. | Teks ketikan White Body/Large, kursor Branding Orange (keputusan Bayu). Disabled tampil seperti Default. | Tambah varian State=Filled (berisi teks dan kursor) dan State=Disabled. | Terbuka |
| F-06 | W1-05 | Components › [03] Form › Checkbox (6:61), Switch (6:68), Chip (6:75); [02] FAB (6:27) | Tidak ada | Tidak ada keadaan Disabled untuk Checkbox, Switch, dan Chip. Tidak ada Hover/Pressed untuk Chip dan FAB, padahal Button punya. | Tampilan tidak berubah saat nonaktif, hover, atau ditekan. | Tambah varian yang dibutuhkan, atau tulis di catatan komponen bahwa keadaan itu memang tidak berubah. | Terbuka |
| F-07 | W1-05 | Components › [03] Form › Checkbox (6:58) | Tidak konsisten | Ikon Check di dalam Checkbox diperkecil ke 18px tapi garisnya tetap 1.5. Catatan [01] Ikon bilang "ubah ukuran instance, garisnya ikut menyesuaikan" (jadi sekitar 1.1). | `AppIcon` ukuran 18, garis ikut mengecil (sekitar 1.1). | Pilih satu aturan: biarkan garis mengecil, atau buat ikon centang 18px khusus dengan garis 1.5. | Terbuka |
| F-08 | W1-05 | Components › Checkbox, Switch, Badge, FAB | Kurang | Beberapa ukuran tidak memakai variabel Figma: sudut Checkbox 6 dan garis 1.5, Switch 46×26 dengan knob 20, tint Badge opacity 20%, FAB 56×56, centang 18px. | Disimpan sebagai konstanta bernama di masing-masing widget (keputusan Bayu). | Opsional: jadikan variabel (misalnya `Radius/Checkbox`) kalau ingin bisa diubah dari satu tempat. | Terbuka |
