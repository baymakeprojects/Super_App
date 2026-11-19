import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/routes.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/features/auth/application/session_controller.dart';
import 'package:super_app/features/auth/data/device_lock.dart';
import 'package:super_app/features/auth/data/pin_store.dart';
import 'package:super_app/features/auth/data/profile_repository.dart';
import 'package:super_app/features/auth/presentation/auth_layout.dart';

/// `/kunci/pin`: H06 Masukkan PIN (Figma 56:2560).
class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  bool _checking = false;

  void _digit(String digit) {
    if (_checking || _pin.length >= PinStore.length) return;
    setState(() => _pin += digit);
    if (_pin.length == PinStore.length) unawaited(_check());
  }

  void _delete() {
    if (_checking || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _check() async {
    _checking = true;
    final ok = await ref.read(pinStoreProvider).verify(_pin);
    _checking = false;
    if (!mounted) return;
    if (ok) {
      ref.read(sessionControllerProvider.notifier).unlock();
      return;
    }
    // Belum ada frame PIN salah (F-49): titik dikosongkan dan HP bergetar.
    unawaited(HapticFeedback.heavyImpact());
    setState(() => _pin = '');
  }

  Future<void> _fingerprint() async {
    final result = await ref.read(deviceLockProvider).unlockWithBiometric();
    if (mounted && result == UnlockResult.success) {
      ref.read(sessionControllerProvider.notifier).unlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(profileNameProvider).value;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        // Isi di tengah ruang di atas keypad (justify-center di Figma):
        // jarak atas dan bawah isi dibuat sama dengan spaceBetween.
        child: FillViewport(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox.shrink(),
              Padding(
                padding: const EdgeInsets.all(AppSpace.s24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: AppSpace.s16,
                  children: [
                    const AppLogoMark(size: AppLogoMarkSize.large),
                    Text(
                      name == null ? 'Halo' : 'Halo, $name',
                      textAlign: TextAlign.center,
                      style: AppText.headingLarge.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      'Masukkan PIN untuk membuka Super App',
                      textAlign: TextAlign.center,
                      style: AppText.bodyMedium.copyWith(color: AppColors.gray),
                    ),
                    // Spacer 8 di Figma (56:2611).
                    const SizedBox(height: AppSpace.s8),
                    AppPinDots(filled: _pin.length),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.masuk),
                      child: AppLabelText(
                        // Teks Figma masih menyebut Google (F-13).
                        'Lupa PIN? Masuk ulang dengan email',
                        textAlign: TextAlign.center,
                        style: AppText.labelMedium.copyWith(
                          color: AppColors.accentText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.s24,
                  AppSpace.s8,
                  AppSpace.s24,
                  AppSpace.s32,
                ),
                child: AppKeypad(
                  onDigit: _digit,
                  onDelete: _delete,
                  onFingerprint: _fingerprint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
