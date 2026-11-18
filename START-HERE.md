# Mulai di sini — kit Claude Code untuk Super App

Folder ini berisi semua yang dibutuhkan Claude Code untuk mengerjakan MVP Super App: aturan proyek, dokumen acuan, skill, hook, dan konfigurasi MCP. Isinya diambil dari dokumen "Rencana Super App Pribadi" dan file Figma per 19 Nov 2026 (tanpa fitur AI).

## Isi folder

```
CLAUDE.md                      aturan proyek, dibaca Claude Code tiap sesi
README.md                      cara menjalankan proyek dari nol
START-HERE.md                  file ini (boleh dihapus setelah setup)
.gitignore
.mcp.json                      MCP Dart & Flutter
.claude/
  settings.json                izin perintah + hook format/analyze
  hooks/dart-check.sh          dart format + dart analyze tiap file .dart diedit
  skills/
    kerjakan-backlog/          /kerjakan-backlog W2-03 → kerjakan 1 tugas backlog
    flutter-screen/            bangun layar persis dari frame Figma
    komponen-ui/               token tema + widget core/ui + golden test
    supabase-tabel/            migrasi + RLS + drift + repository
    cek-desain/                bandingkan app dengan Figma
docs/
  prd.md                       ruang lingkup MVP dan kriteria selesai
  spesifikasi-teknis.md        library, arsitektur, model data, sinkron
  design-notes.md              cara membaca Figma, aturan per layar
  design-tokens.md             warna, teks, spasi, sudut (Figma → Dart)
  navigasi.md                  rute go_router dan pop-up
  figma-frames.md              node id semua frame MVP
  backlog.md                   W1-01 … W4-08 dengan kolom Status
  pengujian-rilis.md           definition of done, checklist rilis
env/dev.example.json           contoh kunci lokal (salin jadi dev.json)
```

## 1. Taruh di repo

- **Repo belum ada:** buat proyek dulu (`flutter create --org com.bayu --platforms android,windows super_app`), lalu salin seluruh isi folder ini ke akar `super_app/` (timpa `.gitignore` dan `README.md`).
- **Repo sudah ada:** salin isinya ke akar repo. Kalau sudah punya `CLAUDE.md`, gabungkan isinya, jangan timpa begitu saja.
- Commit: `git add . && git commit -m "Tambah kit Claude Code"`.

## 2. Pasang yang dibutuhkan Claude Code

| Yang dipasang | Fungsi | Cara | Wajib? |
| --- | --- | --- | --- |
| Plugin Figma (MCP + skill) | Membaca frame, variabel, dan screenshot dari file Super App. Membawa skill `figma-design-to-code`, `figma-use`, `figma-code-connect` | `claude plugin install figma@claude-plugins-official`, lalu di Claude Code `/mcp` → figma → Authenticate dengan akun Figma pemilik file | Wajib |
| Figma MCP saja (kalau plugin tidak bisa) | Sama, tanpa skill bawaan | `claude mcp add --transport http figma https://mcp.figma.com/mcp`, lalu `/mcp` → Authenticate | Alternatif |
| Dart & Flutter MCP | Analisis kode, jalankan tes, hot reload, cari paket pub.dev | Sudah ada di `.mcp.json`; butuh Dart SDK 3.9+ (Flutter 3.47 sudah termasuk). Setujui saat Claude Code bertanya | Disarankan |
| Supabase MCP (hanya proyek **dev**, read-only) | Melihat tabel, migrasi, dan log | `claude mcp add --transport http supabase "https://mcp.supabase.com/mcp?project_ref=<ref-dev>&read_only=true"` | Opsional |

Jangan sambungkan Supabase MCP ke proyek prod.

### Skill yang dipakai

| Skill | Asal | Dipakai untuk |
| --- | --- | --- |
| `kerjakan-backlog` | Kit ini (`.claude/skills`) | Titik masuk utama: satu tugas backlog dari baca acuan sampai commit |
| `flutter-screen` | Kit ini | Setiap layar, keadaan kosong/memuat/gagal, dan pop-up |
| `komponen-ui` | Kit ini | Token tema, ikon, dan widget `core/ui` dengan golden test |
| `supabase-tabel` | Kit ini | Tabel baru: migrasi SQL + RLS, drift, sync_queue, repository |
| `cek-desain` | Kit ini | Membandingkan hasil dengan Figma sebelum commit |
| `figma-design-to-code` | Plugin Figma | Dimuat otomatis oleh `flutter-screen` sebelum `get_design_context` |
| `figma-code-connect` | Plugin Figma | Opsional, nanti: memetakan komponen Figma ke widget `core/ui` |

Skill di `.claude/skills` otomatis terbaca saat Claude Code dibuka di akar repo. Cek dengan mengetik `/` — kelima skill harus muncul.

## 3. Siapkan proyek

Ikuti `README.md` › Langkah pertama kali (Supabase dev, OAuth Google, `env/dev.json`). Hook butuh `bash` (di Windows: Git Bash, sudah terpasang bersama Git).

## 4. Status backlog

Belum ada kode sama sekali, jadi semua tugas di `docs/backlog.md` berstatus `Belum` dan pekerjaan dimulai dari W1-01. Tidak ada tenggat: kerjakan satu tugas per sesi, berurutan.

## 5. Prompt pertama

Buka terminal di akar repo, jalankan `claude`, lalu:

```
Baca CLAUDE.md dan semua file di docs/. Aku belum pernah ngoding proyek ini
dan masih belajar Flutter. Jelaskan singkat gambaran besarnya (fase 1–4),
lalu cek apakah Flutter, Android SDK, dan Dart MCP di laptopku sudah siap
untuk W1-01. Jangan ubah kode dulu.
```

Setelah itu, satu tugas per sesi, mulai dari yang pertama:

```
/kerjakan-backlog W1-01
```

Sesi berikutnya `/clear` dulu, lalu tugas berikutnya. Untuk tugas besar, pakai plan mode (Shift+Tab dua kali) supaya Claude Code menulis rencana sebelum mengubah file.

## Catatan

- Figma adalah sumber kebenaran tampilan. Kalau Claude Code bertanya karena desain tidak jelas, jawab atau perbaiki Figma-nya, jangan biarkan menebak.
- Node id di `docs/figma-frames.md` bisa berubah kalau frame dihapus dan dibuat ulang; minta Claude Code memperbaruinya kalau ada yang tidak ditemukan.
- Fitur AI sudah dihapus dari rencana. `CLAUDE.md` melarang Claude Code menambahkannya.
