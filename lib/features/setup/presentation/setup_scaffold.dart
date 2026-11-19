import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/features/auth/application/session_controller.dart';
import 'package:super_app/features/auth/presentation/auth_layout.dart';

/// Kerangka Setup awal 01a–01c (Figma 66:1786, 66:1852, 66:1898): langkah
/// dan "Lewati", progress bar, judul, isi, lalu satu tombol di bawah.
class SetupScaffold extends ConsumerWidget {
  const SetupScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.body,
    required this.children,
    required this.actionLabel,
    required this.onAction,
  });

  static const int steps = 3;

  /// Progres tiap langkah di Figma (30, 70, 100).
  static const List<double> _progress = [30, 70, 100];

  /// Langkah 1–3.
  final int step;
  final String title;
  final String body;
  final List<Widget> children;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = step == steps;
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.s24,
                      AppSpace.s12,
                      AppSpace.s24,
                      AppSpace.s8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpace.s12,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppLabelText(
                              'Langkah $step dari $steps',
                              style: AppText.labelSmall.copyWith(
                                color: AppColors.gray,
                              ),
                            ),
                            // Langkah terakhir tanpa "Lewati"; Figma
                            // memakai teks kosong supaya tinggi baris sama.
                            if (last)
                              const Text(' ', style: AppText.labelMedium)
                            else
                              GestureDetector(
                                onTap: () => ref
                                    .read(sessionControllerProvider.notifier)
                                    .finishSetup(),
                                child: AppLabelText(
                                  'Lewati',
                                  style: AppText.labelMedium.copyWith(
                                    color: AppColors.lightGray,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        AppProgressBar(value: _progress[step - 1]),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.s24,
                      AppSpace.s16,
                      AppSpace.s24,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpace.s20,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: AppSpace.s8,
                          children: [
                            Text(
                              title,
                              style: AppText.headingLarge.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                            Text(
                              body,
                              style: AppText.bodyLarge.copyWith(
                                color: AppColors.lightGray,
                              ),
                            ),
                          ],
                        ),
                        ...children,
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
                child: AppButton(label: actionLabel, onPressed: onAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
