import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/features/auth/application/session_controller.dart';
import 'package:super_app/features/auth/data/pin_store.dart';
import 'package:super_app/features/auth/presentation/auth_layout.dart';

/// `/pengaturan/pin`: H05 Atur PIN cadangan (Figma 56:2490). Langkah 1
/// membuat PIN, langkah 2 mengulanginya. Juga dipakai untuk mengganti PIN.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _circle = 64;
  static const double _iconSize = 28;
  static const double _captionWidth = 300;

  String _pin = '';

  /// PIN langkah 1; `null` = masih di langkah 1.
  String? _first;
  bool _saving = false;

  void _digit(String digit) {
    if (_saving || _pin.length >= PinStore.length) return;
    setState(() => _pin += digit);
    if (_pin.length == PinStore.length) unawaited(_complete());
  }

  void _delete() {
    if (_saving || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _complete() async {
    final first = _first;
    if (first == null) {
      setState(() {
        _first = _pin;
        _pin = '';
      });
      return;
    }
    if (_pin != first) {
      // Belum ada frame PIN tidak sama (F-55): titik dikosongkan dan HP
      // bergetar, tetap di langkah 2.
      unawaited(HapticFeedback.heavyImpact());
      setState(() => _pin = '');
      return;
    }
    _saving = true;
    await ref.read(pinStoreProvider).setPin(_pin);
    ref.invalidate(hasPinProvider);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final confirming = _first != null;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppTopAppBar(
        title: 'PIN cadangan',
        leadingIcon: AppIcons.arrowLeft,
        onLeadingPressed: context.pop,
        leadingSemanticLabel: 'Kembali',
      ),
      body: SafeArea(
        top: false,
        child: FillViewport(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox.shrink(),
              Padding(
                padding: const EdgeInsets.all(AppSpace.s24),
                child: Column(
                  spacing: AppSpace.s16,
                  children: [
                    Container(
                      width: _circle,
                      height: _circle,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.darkGray),
                      ),
                      child: const AppIcon(
                        AppIcons.lock,
                        color: AppColors.brandingOrange,
                        size: _iconSize,
                      ),
                    ),
                    Text(
                      // Langkah 2 belum punya frame (F-55).
                      confirming ? 'Ulangi PIN cadangan' : 'Buat PIN cadangan',
                      textAlign: TextAlign.center,
                      style: AppText.headingMedium.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(
                      width: _captionWidth,
                      child: Text(
                        'Dipakai kalau sidik jari gagal. 6 angka, hindari '
                        'tanggal lahir.',
                        textAlign: TextAlign.center,
                        style: AppText.bodyMedium.copyWith(
                          color: AppColors.gray,
                        ),
                      ),
                    ),
                    // Spacer 8 di Figma (56:2551).
                    const SizedBox(height: AppSpace.s8),
                    AppPinDots(filled: _pin.length),
                    AppLabelText(
                      confirming
                          ? 'Langkah 2 dari 2 · ketik ulang PIN yang sama'
                          : 'Langkah 1 dari 2 · ulangi PIN di langkah '
                                'berikutnya',
                      textAlign: TextAlign.center,
                      style: AppText.labelSmall.copyWith(color: AppColors.gray),
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
                  showFingerprint: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
