import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/routes.dart';
import 'package:super_app/core/sync/sync_status.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/core/utils/date_format.dart';
import 'package:super_app/features/auth/application/session_controller.dart';
import 'package:super_app/features/auth/data/device_lock.dart';
import 'package:super_app/features/auth/data/profile_repository.dart';
import 'package:super_app/features/auth/presentation/auth_layout.dart';

/// Sidik jari gagal sekian kali → pindah ke PIN (navigasi.md).
const int maxFingerprintFailures = 3;

/// `/kunci`: 01 Kunci sidik jari (Figma 12:2), atau G1 Sesi berakhir
/// (137:4097) kalau sesi akun sudah tidak berlaku.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  int _failures = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Prompt sidik jari sistem langsung muncul (design-notes §01).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _locked) unawaited(_fingerprint());
    });
  }

  bool get _locked =>
      ref.read(sessionControllerProvider).status == SessionStatus.locked;

  void _unlock() => ref.read(sessionControllerProvider.notifier).unlock();

  Future<void> _fingerprint() async {
    if (_busy) return;
    _busy = true;
    final result = await ref.read(deviceLockProvider).unlockWithBiometric();
    _busy = false;
    if (!mounted) return;
    switch (result) {
      case UnlockResult.success:
        _unlock();
      case UnlockResult.unavailable:
        // HP tanpa sensor atau belum ada sidik jari terdaftar.
        await _usePin();
      case UnlockResult.failed:
        _failures++;
        if (_failures >= maxFingerprintFailures) await _usePin();
      case UnlockResult.canceled:
        break;
    }
  }

  /// "Pakai PIN perangkat": PIN cadangan app (H06) kalau sudah diatur,
  /// kalau belum, kunci layar HP lewat prompt sistem (F-50).
  Future<void> _usePin() async {
    if (await ref.read(pinStoreProvider).hasPin()) {
      if (mounted) await context.push(AppRoutes.kunciPin);
      return;
    }
    if (_busy) return;
    _busy = true;
    final result = await ref
        .read(deviceLockProvider)
        .unlockWithDeviceCredential();
    _busy = false;
    if (!mounted) return;
    // HP tanpa kunci layar sama sekali: tidak ada yang bisa dicocokkan.
    if (result == UnlockResult.success || result == UnlockResult.unavailable) {
      _unlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final expired =
        ref.watch(sessionControllerProvider).status == SessionStatus.expired;
    final name = ref.watch(profileNameProvider).value;
    final title = greetingTitle(name);

    if (expired) {
      final lastSynced = ref.watch(lastSyncedAtProvider).value;
      return AuthScaffold(
        children: [
          AuthGreeting(
            title: title,
            // Teks Figma masih menyebut Google (F-13).
            body:
                'Sesi akunmu berakhir. Masuk lagi dengan email supaya data '
                'tetap tersinkron.',
          ),
          const Opacity(
            opacity: _expiredSensorOpacity,
            child: _Sensor(status: 'Perlu masuk ulang'),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.s16,
            children: [
              const AppBanner(
                type: AppBannerType.danger,
                title: 'Sesi akun berakhir',
                body: 'Data di HP aman. Perubahan terakhir belum tersinkron.',
              ),
              AppButton(
                label: 'Masuk lagi',
                onPressed: () => context.push(AppRoutes.masuk),
              ),
              if (lastSynced != null)
                AuthSyncLine(
                  'Belum tersinkron sejak ${AppDateFormat.time(lastSynced)}',
                ),
            ],
          ),
        ],
      );
    }

    return AuthScaffold(
      children: [
        AuthGreeting(
          title: title,
          body:
              'Sentuh sensor sidik jari untuk membuka tugas, jadwal kuliah, '
              'dan keuanganmu.',
        ),
        GestureDetector(
          onTap: _fingerprint,
          child: const _Sensor(status: 'Menunggu sidik jari…'),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.s16,
          children: [
            AppButton(
              label: 'Pakai PIN perangkat',
              style: AppButtonStyle.ghost,
              onPressed: _usePin,
            ),
            const AuthSyncLine('Tersinkron · Android & desktop'),
          ],
        ),
      ],
    );
  }

  /// G1: sensor dibuat pudar 35%.
  static const double _expiredSensorOpacity = 0.35;
}

/// Bagian Sensor: Dot Matrix 280 dan teks status di bawahnya.
class _Sensor extends StatelessWidget {
  const _Sensor({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: AppSpace.s12,
      children: [
        const AppIllustration(AppIllustrations.sensorDotMatrix),
        AppLabelText(
          status,
          style: AppText.labelSmall.copyWith(color: AppColors.gray),
        ),
      ],
    );
  }
}
