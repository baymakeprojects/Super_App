import 'package:local_auth/local_auth.dart';

/// Hasil satu percobaan membuka kunci.
enum UnlockResult {
  /// Berhasil.
  success,

  /// Sidik jari tidak cocok atau terlalu banyak percobaan.
  failed,

  /// Pengguna menutup prompt.
  canceled,

  /// Cara ini tidak bisa dipakai di HP ini (tidak ada sensor, atau belum
  /// ada sidik jari/kunci layar terdaftar).
  unavailable,
}

/// Kunci perangkat: sidik jari atau kunci layar HP lewat prompt sistem.
abstract interface class DeviceLock {
  /// Prompt sidik jari (hanya biometrik).
  Future<UnlockResult> unlockWithBiometric();

  /// Prompt kunci layar HP (PIN, pola, atau sandi perangkat).
  Future<UnlockResult> unlockWithDeviceCredential();
}

/// [DeviceLock] lewat paket local_auth (BiometricPrompt Android).
class LocalAuthDeviceLock implements DeviceLock {
  LocalAuthDeviceLock();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Judul prompt sistem (prompt bukan bagian dari frame Figma).
  static const String _reason = 'Buka Super App';

  @override
  Future<UnlockResult> unlockWithBiometric() => _run(biometricOnly: true);

  @override
  Future<UnlockResult> unlockWithDeviceCredential() =>
      _run(biometricOnly: false);

  Future<UnlockResult> _run({required bool biometricOnly}) async {
    try {
      if (!await _auth.isDeviceSupported()) return UnlockResult.unavailable;
      final ok = await _auth.authenticate(
        localizedReason: _reason,
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: true,
      );
      return ok ? UnlockResult.success : UnlockResult.failed;
    } on LocalAuthException catch (error) {
      return switch (error.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.authInProgress ||
        LocalAuthExceptionCode.userRequestedFallback => UnlockResult.canceled,
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable ||
        LocalAuthExceptionCode.uiUnavailable => UnlockResult.unavailable,
        _ => UnlockResult.failed,
      };
    }
  }
}
