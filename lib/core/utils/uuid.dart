import 'dart:math';

final Random _random = Random.secure();

/// Membuat UUID versi 4 acak (RFC 9562), misalnya
/// `3f2b8c1e-9a4d-4f6e-b2c7-1d5e8a9b0c3f`.
///
/// Id baris dibuat di HP supaya data bisa disimpan offline lalu dikirim ke
/// Supabase dengan id yang sama.
String newUuidV4() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // versi 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // varian RFC

  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
