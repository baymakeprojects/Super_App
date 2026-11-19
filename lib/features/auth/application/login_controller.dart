import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/features/auth/application/session_controller.dart';
import 'package:super_app/features/auth/data/auth_repository.dart';

/// Kode berlaku 10 menit (setup-supabase.md › Email OTP Expiration 600).
const Duration codeLifetime = Duration(minutes: 10);

/// Jeda sebelum kode boleh dikirim ulang (batas Supabase: 1 email per
/// 60 detik untuk alamat yang sama).
const Duration resendCooldown = Duration(seconds: 60);

/// Format email sederhana: ada satu @ dan titik di bagian domain.
bool isValidEmail(String email) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());

/// Kenapa kode tidak diterima di 00f.
enum CodeError {
  /// Kode salah (frame 231:5310).
  wrong,

  /// Kode lewat 10 menit (frame 231:5349).
  expired,

  /// Tidak ada internet saat memeriksa.
  network,
}

class CodeCheckException implements Exception {
  const CodeCheckException(this.error);

  final CodeError error;

  @override
  String toString() => 'CodeCheckException($error)';
}

/// Email yang sedang dipakai masuk dan waktu kode terakhir dikirim.
@immutable
class LoginFlow {
  const LoginFlow({required this.email, required this.sentAt});

  final String email;
  final DateTime sentAt;
}

final loginControllerProvider = NotifierProvider<LoginController, LoginFlow?>(
  LoginController.new,
);

/// Alur 00e → 00f: kirim kode ke email, lalu cocokkan kodenya.
class LoginController extends Notifier<LoginFlow?> {
  @override
  LoginFlow? build() => null;

  AuthRepository get _auth {
    final auth = ref.read(authRepositoryProvider);
    if (auth == null) {
      throw StateError('Supabase belum diatur (jalankan dengan file env).');
    }
    return auth;
  }

  /// Kirim kode ke [email]. Melempar kalau gagal (misalnya offline).
  Future<void> sendCode(String email) async {
    final trimmed = email.trim();
    await _auth.sendCode(trimmed);
    state = LoginFlow(email: trimmed, sentAt: ref.read(clockProvider)());
  }

  /// Kirim ulang kode ke email yang sama.
  Future<void> resendCode() async {
    final flow = state;
    if (flow == null) return;
    await sendCode(flow.email);
  }

  /// Cocokkan [code]; kalau cocok, akun dibuka. Melempar
  /// [CodeCheckException].
  Future<void> verifyCode(String code) async {
    final flow = state;
    if (flow == null) throw const CodeCheckException(CodeError.expired);
    final String userId;
    try {
      userId = await _auth.verifyCode(email: flow.email, code: code);
    } on CodeRejectedException catch (error) {
      if (error.reason == CodeRejection.network) {
        throw const CodeCheckException(CodeError.network);
      }
      throw CodeCheckException(
        isCodeExpired(flow) ? CodeError.expired : CodeError.wrong,
      );
    }
    await ref.read(sessionControllerProvider.notifier).signedIn(userId);
    state = null;
  }

  /// Kode di [flow] sudah lewat masa berlakunya.
  bool isCodeExpired(LoginFlow flow) =>
      !ref.read(clockProvider)().isBefore(flow.sentAt.add(codeLifetime));
}
