# Progres landing page (sementara — hapus setelah selesai)

Sudah:
- Figma landing diperbarui sesuai v0.1.0 (lihat docs/catatan-figma.md, bagian Landing page).
- Aset SVG dari Figma diunduh ke website/assets/{hero,icons}.

Belum:
1. Tulis situs statis HTML/CSS di website/: index.html (Landing 161:3 / 164:777),
   unduh/android/index.html (177:1266 desktop = QR + Salin link; 177:1338 HP = "Unduhan dimulai", auto-unduh),
   404.html (182:1665 / 182:1702), menu HP (183:1805). Token dari docs/design-tokens.md, font dari assets/fonts.
   Tambahan dari Figma: Display/XL Doto 96/92/-2, Heading/XL Geist Medium 44/1.16/-0.88.
2. Link APK: ambil asset terbaru lewat GitHub API (releases/latest, nama super-app-vX.Y.Z.apk), cadangan ke halaman releases/latest.
3. QR di Unduh Android & kartu Unduh: perlu generator QR (belum ada paket; tanya Bayu sebelum menambah library).
4. Workflow GitHub Pages (.github/workflows), aksi dikunci ke SHA seperti rilis-apk.yml.
5. Bandingkan dengan Figma, perbarui docs (design-notes: Landing tidak lagi "abaikan"; figma-frames), commit, merge --ff-only ke main.
