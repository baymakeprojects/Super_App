import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/placeholder_screen.dart';
import 'package:super_app/app/routes.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';

/// `/lainnya`: 06 Lainnya versi MVP (Figma 257:6514, F-66). Semua modul
/// Tahap 2–3 tampil sebagai Module Tile keadaan Segera (tidak bisa
/// diketuk); label jumlah modul tetap disembunyikan. Saat sebuah modul
/// selesai, tile-nya berganti ke keadaan normal (design-notes §7). Ikon
/// User membuka Pengaturan.
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
            const SizedBox(height: AppSpace.s20),
            const _ModuleGrid(),
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

/// Modul Tahap 2–3 sesuai urutan grid Modules di frame 257:6514.
const List<(AppIcons, String)> _modules = [
  (AppIcons.timer, 'Fokus'),
  (AppIcons.flame, 'Kebiasaan'),
  (AppIcons.note, 'Catatan'),
  (AppIcons.book, 'Skripsi'),
  (AppIcons.learn, 'Belajar'),
  (AppIcons.folder, 'Proyek'),
  (AppIcons.chart, 'Statistik'),
  (AppIcons.calendar, 'Kalender'),
  (AppIcons.check, 'Nilai & IPK'),
  (AppIcons.home, 'KKN'),
];

/// Grid dua kolom Module Tile (auto-layout wrap di Figma, jarak 12).
class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid();

  static const int _columns = 2;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: AppSpace.s12,
      children: [
        for (var i = 0; i < _modules.length; i += _columns)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.s12,
            children: [
              for (var j = i; j < i + _columns; j++)
                Expanded(
                  child: j < _modules.length
                      ? AppModuleTile(
                          icon: _modules[j].$1,
                          title: _modules[j].$2,
                          state: AppModuleTileState.segera,
                        )
                      : const SizedBox.shrink(),
                ),
            ],
          ),
      ],
    );
  }
}
