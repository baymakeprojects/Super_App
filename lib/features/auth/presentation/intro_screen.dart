import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/routes.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/features/auth/presentation/auth_layout.dart';

/// `/intro`: 00d Intro 4 (Figma 63:1997). Intro 00a–00c menyusul di W4-03;
/// sampai itu intro langsung mulai dari 00d (navigasi.md).
class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: FillViewport(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Logo(),
                  const _Illustration(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.s24,
                      AppSpace.s8,
                      AppSpace.s24,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpace.s12,
                      children: [
                        AppLabelText(
                          '[04] Aman & sinkron',
                          style: AppText.labelSmall.copyWith(
                            color: AppColors.accentText,
                          ),
                        ),
                        Text(
                          'Terkunci sidik jari,\nsinkron ke desktop',
                          style: AppText.headingLarge.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        Text(
                          'Hanya kamu yang bisa membuka app. Data tersimpan di '
                          'cloud dan otomatis sama di HP dan desktop.',
                          style: AppText.bodyLarge.copyWith(
                            color: AppColors.lightGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.s24,
                  AppSpace.s16,
                  AppSpace.s24,
                  AppSpace.s32,
                ),
                child: Column(
                  spacing: AppSpace.s24,
                  children: [
                    const AppPageIndicator(page: 4),
                    AppButton(
                      label: 'Mulai sekarang →',
                      onPressed: () => context.push(AppRoutes.masuk),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logo kecil di kiri atas (63:2010).
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Figma: padding 24/12 baris atas + 12 di kiri logo.
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s24 + AppSpace.s12,
        AppSpace.s12,
        AppSpace.s24,
        AppSpace.s12,
      ),
      child: Row(
        spacing: AppSpace.s12,
        children: [
          const AppLogoMark(),
          AppLabelText(
            'Super App',
            style: AppText.labelLarge.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

/// Ilustrasi 00d (63:2014): kotak 412×420 di tengah, posisi elemen sama
/// dengan Figma.
class _Illustration extends StatelessWidget {
  const _Illustration();

  // Ukuran dan posisi tetap dari frame Figma (bukan variabel Figma).
  static const double _width = 412;
  static const double _height = 420;
  static const double _circle = 128;
  static const double _chip = 52;
  static const double _statusDot = 8;
  static const double _ringBorder = 1.5;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: ClipRect(
        child: OverflowBox(
          maxWidth: _width,
          minWidth: _width,
          child: Stack(
            children: [
              const Positioned(
                left: 36,
                top: 40,
                child: AppIllustration(AppIllustrations.introGlow),
              ),
              const Positioned(
                left: 53,
                top: 57,
                child: AppIllustration(AppIllustrations.introRing),
              ),
              Positioned(
                left: 142,
                top: 130,
                child: Container(
                  width: _circle,
                  height: _circle,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.brandingOrange,
                      width: _ringBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.55),
                        offset: const Offset(0, 16),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const AppIllustration(
                    AppIllustrations.introFingerprint,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 282,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.s16,
                      vertical: AppSpace.s8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: AppColors.darkGray),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: AppSpace.s8,
                      children: [
                        Container(
                          width: _statusDot,
                          height: _statusDot,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        AppLabelText(
                          'Tersinkron · HP & desktop',
                          style: AppText.labelSmall.copyWith(
                            color: AppColors.lightGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 50,
                top: 109,
                child: _IconChip(AppIcons.lock),
              ),
              const Positioned(
                left: 310,
                top: 109,
                child: _IconChip(AppIcons.refresh),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip(this.icon);

  final AppIcons icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _Illustration._chip,
      height: _Illustration._chip,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.item),
        border: Border.all(color: AppColors.darkGray),
      ),
      child: AppIcon(icon, color: AppColors.lightGray),
    );
  }
}
