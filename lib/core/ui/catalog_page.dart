import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';

/// Katalog komponen `core/ui` untuk dicek di HP. **Hanya untuk build debug**;
/// bukan layar Figma dan tidak boleh muncul di rilis.
///
/// Belum punya rute: go_router dibuat di W1-09.
class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  bool _checked = true;
  bool _switchOn = true;
  int _selectedChip = 0;

  static const _chips = ['Semua', 'Hari ini', 'Minggu ini', 'Selesai'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.s16),
          children: [
            const _Section('Ikon'),
            Wrap(
              spacing: AppSpace.s16,
              runSpacing: AppSpace.s16,
              children: [for (final icon in AppIcons.values) AppIcon(icon)],
            ),
            const _Section('Button'),
            for (final style in AppButtonStyle.values) ...[
              Wrap(
                spacing: AppSpace.s8,
                runSpacing: AppSpace.s8,
                children: [
                  for (final state in AppButtonState.values)
                    AppButton(
                      label: 'Simpan →',
                      style: style,
                      expand: false,
                      onPressed: () {},
                      previewState: state,
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.s8),
            ],
            AppButton(label: 'Simpan →', onPressed: () {}),
            const _Section('FAB'),
            Align(
              alignment: Alignment.centerLeft,
              child: AppFab(onPressed: () {}, semanticLabel: 'Tambah'),
            ),
            const _Section('Input'),
            const AppInput(
              label: 'Judul tugas',
              placeholder: 'Contoh: laporan praktikum',
            ),
            const SizedBox(height: AppSpace.s16),
            const AppInput(
              label: 'Judul tugas',
              placeholder: 'Contoh: laporan praktikum',
              errorText: 'Wajib diisi',
            ),
            const _Section('Checkbox · Switch'),
            Row(
              spacing: AppSpace.s24,
              children: [
                AppCheckbox(
                  value: _checked,
                  onChanged: (value) => setState(() => _checked = value),
                ),
                AppSwitch(
                  value: _switchOn,
                  onChanged: (value) => setState(() => _switchOn = value),
                ),
              ],
            ),
            const _Section('Chip'),
            Wrap(
              spacing: AppSpace.s8,
              runSpacing: AppSpace.s8,
              children: [
                for (var i = 0; i < _chips.length; i++)
                  AppChip(
                    label: _chips[i],
                    selected: i == _selectedChip,
                    onTap: () => setState(() => _selectedChip = i),
                  ),
              ],
            ),
            const _Section('Badge'),
            const Wrap(
              spacing: AppSpace.s8,
              children: [
                AppBadge(label: 'Besok'),
                AppBadge(label: 'Selesai', type: AppBadgeType.success),
                AppBadge(label: 'Hari ini', type: AppBadgeType.warning),
                AppBadge(label: 'Terlambat', type: AppBadgeType.danger),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s32, bottom: AppSpace.s12),
      child: Text(
        title.toUpperCase(),
        style: AppText.labelSmall.copyWith(color: AppColors.gray),
      ),
    );
  }
}
