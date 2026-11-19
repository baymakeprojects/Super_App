import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/routes.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';

/// Layar sementara berjudul untuk rute yang layarnya belum dibuat (W1-09).
/// Setiap layar asli menggantikan placeholder-nya; ini bukan desain Figma.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.inShell = false,
    this.showDebugRoutes = false,
  });

  final String title;

  /// `true` untuk tab Bottom Nav (tanpa Top App Bar).
  final bool inShell;

  /// Daftar tombol ke semua rute, hanya di build debug, supaya semua rute
  /// bisa dicoba di HP sebelum layarnya dibuat.
  final bool showDebugRoutes;

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();

    return Scaffold(
      appBar: inShell
          ? null
          : AppTopAppBar(
              title: title,
              leadingIcon: canPop ? AppIcons.arrowLeft : null,
              onLeadingPressed: canPop ? context.pop : null,
              leadingSemanticLabel: 'Kembali',
            ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.s16),
          children: [
            if (inShell)
              Text(
                title,
                style: AppText.headingLarge.copyWith(color: AppColors.white),
              ),
            const SizedBox(height: AppSpace.s8),
            AppLabelText(
              'Layar belum dibuat',
              style: AppText.labelSmall.copyWith(color: AppColors.gray),
            ),
            if (showDebugRoutes && kDebugMode) ...[
              const SizedBox(height: AppSpace.s24),
              const DebugRouteList(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tombol ke semua rute (hanya build debug), supaya rute yang belum punya
/// layar bisa dicoba di HP.
class DebugRouteList extends StatelessWidget {
  const DebugRouteList({super.key});

  static final List<String> _routes = [
    AppRoutes.katalog,
    AppRoutes.intro,
    AppRoutes.kunci,
    AppRoutes.kunciPin,
    AppRoutes.setupJadwal,
    AppRoutes.setupDompet,
    AppRoutes.setupKeamanan,
    AppRoutes.tugasBaru,
    AppRoutes.tugasCari,
    AppRoutes.tugasDetail('contoh'),
    AppRoutes.tugasEdit('contoh'),
    AppRoutes.kuliahJadwalBaru,
    AppRoutes.kuliahDetail('contoh'),
    AppRoutes.kuliahEdit('contoh'),
    AppRoutes.keuanganTransaksiBaru,
    AppRoutes.keuanganTransaksi('contoh'),
    AppRoutes.pengaturan,
    AppRoutes.pengaturanPin,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.s8,
      children: [
        AppLabelText(
          'Rute debug',
          style: AppText.labelSmall.copyWith(color: AppColors.gray),
        ),
        for (final route in _routes)
          AppButton(
            label: route,
            style: AppButtonStyle.ghost,
            onPressed: () => context.push(route),
          ),
      ],
    );
  }
}
