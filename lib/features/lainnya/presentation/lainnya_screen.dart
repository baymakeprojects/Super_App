import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/placeholder_screen.dart';
import 'package:super_app/app/routes.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';

/// `/lainnya`: 06 Lainnya versi MVP (Figma 158:15114). Grid modul dan
/// label jumlah modul (Tahap 2–3) disembunyikan; tile muncul satu per satu
/// saat modulnya selesai (design-notes §7). Ikon User membuka Pengaturan.
///
/// Build debug menambah daftar rute debug di bawah judul (disetujui Bayu,
/// W1-09); tidak ada di build rilis.
class LainnyaScreen extends StatelessWidget {
  const LainnyaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.s20,
            AppSpace.s12,
            AppSpace.s20,
            AppSpace.s24,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Lainnya',
                    style: AppText.headingLarge.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
                AppCircleButton(
                  icon: AppIcons.user,
                  semanticLabel: 'Pengaturan',
                  onPressed: () => context.push(AppRoutes.pengaturan),
                ),
              ],
            ),
            if (kDebugMode) ...[
              const SizedBox(height: AppSpace.s24),
              const DebugRouteList(),
            ],
          ],
        ),
      ),
    );
  }
}
