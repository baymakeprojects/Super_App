import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:super_app/core/sync/sync_status.dart';

/// Kenapa kode verifikasi ditolak.
enum CodeRejection {
  /// Server menolak kode: salah atau sudah kedaluwarsa (Supabase memberi
  /// galat yang sama untuk keduanya).
  rejected,

  /// Tidak ada internet.
  network,
}

class CodeRejectedException implements Exception {
  const CodeRejectedException(this.reason);

  final CodeRejection reason;

  @override
  String toString() => 'CodeRejectedException($reason)';
}

/// Login email + kode verifikasi (tanpa password). Layar tidak memanggil
/// Supabase langsung, selalu lewat antarmuka ini.
abstract interface class AuthRepository {
  /// Id akun yang sesinya tersimpan di HP, `null` kalau belum login.
  String? get currentUserId;

  /// Email akun yang login (kartu akun di 14 dan P37).
  String? get currentEmail;

  /// Berbunyi saat sesi hilang bukan karena keluar sendiri, misalnya token
  /// tidak bisa diperbarui lagi (G1 Sesi berakhir).
  Stream<void> get sessionExpired;

  /// Kirim kode 6 digit ke [email]. Akun baru dibuat otomatis.
  Future<void> sendCode(String email);

  /// Cocokkan [code]. Mengembalikan id akun; melempar
  /// [CodeRejectedException] kalau ditolak.
  Future<String> verifyCode({required String email, required String code});

  Future<void> signOut();
}

/// [AuthRepository] lewat Supabase Auth (`signInWithOtp` lalu `verifyOTP`).
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);

  final GoTrueClient _auth;
  bool _signingOut = false;

  @override
  String? get currentUserId => _auth.currentUser?.id;

  @override
  String? get currentEmail => _auth.currentUser?.email;

  @override
  Stream<void> get sessionExpired => _auth.onAuthStateChange
      .where((change) => change.event == AuthChangeEvent.signedOut)
      .where((_) => !_signingOut);

  @override
  Future<void> sendCode(String email) =>
      _auth.signInWithOtp(email: email, shouldCreateUser: true);

  @override
  Future<String> verifyCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: code,
      );
      final user = response.user;
      if (user == null) {
        throw const CodeRejectedException(CodeRejection.rejected);
      }
      return user.id;
    } on AuthRetryableFetchException {
      throw const CodeRejectedException(CodeRejection.network);
    } on AuthException catch (error) {
      throw CodeRejectedException(
        isNetworkError(error) ? CodeRejection.network : CodeRejection.rejected,
      );
    }
  }

  @override
  Future<void> signOut() async {
    _signingOut = true;
    try {
      await _auth.signOut();
    } finally {
      _signingOut = false;
    }
  }
}
