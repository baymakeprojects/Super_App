/// Nilai tetap yang disimpan sebagai teks, sama dengan `check` di migrasi
/// Supabase (`supabase/migrations/*_mvp_tables.sql`). Nama enum = nilai teks.
library;

/// Prioritas tugas (chip Rendah, Sedang, Tinggi).
enum TaskPriority { low, medium, high }

/// Status tugas.
enum TaskStatus { active, done }

/// Jenis dompet: tunai, bank, e-wallet.
enum WalletKind { cash, bank, ewallet }

/// Arah uang untuk kategori dan transaksi: pemasukan atau pengeluaran.
enum MoneyKind { income, expense }

/// Jenis perubahan yang menunggu dikirim ke Supabase.
/// `delete` = soft delete (mengisi `deleted_at`), bukan hapus permanen.
enum SyncOperation { insert, update, delete }
