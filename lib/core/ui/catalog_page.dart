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
  int _tab = 0;
  bool _taskDone = false;
  int _segment = 0;
  int _option = 0;
  int _dayPill = 4;
  DateTime? _date;
  int _hour = 23;
  int _minute = 59;

  static const _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum'];

  static const _chips = ['Semua', 'Hari ini', 'Minggu ini', 'Selesai'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopAppBar(
        title: 'Katalog komponen',
        leadingIcon: AppIcons.arrowLeft,
        onLeadingPressed: () => Navigator.maybePop(context),
        trailingIcon: AppIcons.search,
        onTrailingPressed: () {},
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _tab,
        onTap: (index) => setState(() => _tab = index),
      ),
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
            const _Section('Section Header'),
            AppSectionHeader(
              title: 'Tugas hari ini',
              actionLabel: 'Lihat semua →',
              onActionPressed: () {},
            ),
            const _Section('Card · Stat Card'),
            const AppCard(
              eyebrow: '[01] Label',
              title: 'Judul kartu',
              body:
                  'Isi kartu singkat, maksimal dua baris supaya tetap ringkas.',
            ),
            const SizedBox(height: AppSpace.s12),
            const Row(
              spacing: AppSpace.s12,
              children: [
                Expanded(
                  child: AppStatCard(
                    label: 'Tugas aktif',
                    value: '5',
                    caption: '2 jatuh tempo hari ini',
                  ),
                ),
                Expanded(
                  child: AppStatCard(
                    label: 'Saldo',
                    value: 'Rp1,25jt',
                    caption: '3 dompet',
                  ),
                ),
              ],
            ),
            const _Section('Progress Bar'),
            for (final value in const [0.0, 30.0, 60.0, 100.0]) ...[
              AppProgressBar(value: value),
              const SizedBox(height: AppSpace.s12),
            ],
            const _Section('Task Item · Checklist Item'),
            AppTaskItem(
              title: 'Laporan praktikum modul 5',
              meta: 'Pemrograman Mobile · 23.59',
              done: _taskDone,
              badge: _taskDone
                  ? const AppBadge(label: 'Selesai', type: AppBadgeType.success)
                  : const AppBadge(
                      label: 'Hari ini',
                      type: AppBadgeType.warning,
                    ),
              onDoneChanged: (value) => setState(() => _taskDone = value),
            ),
            AppChecklistItem(
              label: 'Tulis analisis',
              done: _taskDone,
              onChanged: (value) => setState(() => _taskDone = value),
            ),
            const _Section('Class Item · Day Pill'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < _days.length; i++)
                  AppDayPill(
                    day: _days[i],
                    date: '${3 + i}',
                    selected: i == _dayPill,
                    onTap: () => setState(() => _dayPill = i),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.s12),
            for (final state in AppClassItemState.values) ...[
              AppClassItem(
                start: '08.00',
                end: '09.40',
                course: 'Pemrograman Mobile',
                meta: 'Ruang 301 · Bu Rina',
                state: state,
              ),
              const SizedBox(height: AppSpace.s12),
            ],
            const _Section('Segmented Control · Select'),
            AppSegmentedControl(
              firstLabel: 'Pengeluaran',
              secondLabel: 'Pemasukan',
              selectedIndex: _segment,
              onChanged: (index) => setState(() => _segment = index),
            ),
            const SizedBox(height: AppSpace.s16),
            AppSelect(label: 'Mata kuliah', value: null, onTap: () {}),
            const _Section('Pop-up'),
            const AppOverlayHeader(
              title: 'Pilih dompet',
              subtitle: 'Keterangan singkat',
            ),
            for (var i = 0; i < 3; i++)
              AppOptionItem(
                title: ['Tunai', 'Bank', 'E-wallet'][i],
                icon: AppIcons.wallet,
                selected: i == _option,
                onTap: () => setState(() => _option = i),
              ),
            const SizedBox(height: AppSpace.s16),
            AppDatePicker(
              selected: _date,
              onSelected: (date) => setState(() => _date = date),
            ),
            const SizedBox(height: AppSpace.s16),
            AppTimePicker(
              hour: _hour,
              minute: _minute,
              onChanged: (hour, minute) => setState(() {
                _hour = hour;
                _minute = minute;
              }),
            ),
            const _Section('Snackbar · Action Bar'),
            AppButton(
              label: 'Tampilkan snackbar',
              style: AppButtonStyle.ghost,
              onPressed: () => showAppSnackbar(
                context,
                message: 'Tugas dihapus',
                actionLabel: 'Urungkan',
              ),
            ),
            const SizedBox(height: AppSpace.s16),
            AppActionBar(
              primaryLabel: 'Simpan',
              onPrimaryPressed: () {},
              secondaryLabel: 'Hapus',
              onSecondaryPressed: () {},
            ),
            const _Section('Keuangan · Banner'),
            const Row(
              spacing: AppSpace.s12,
              children: [
                AppWalletCard(label: 'Tunai', amount: 'Rp150.000'),
                AppWalletCard(label: 'Bank', amount: 'Rp1.250.000'),
              ],
            ),
            const SizedBox(height: AppSpace.s16),
            const AppTransactionItem(
              title: 'Makan siang',
              meta: 'Tunai · Makan · 12.30',
              amount: 'Rp25.000',
              type: AppTransactionType.expense,
            ),
            const AppTransactionItem(
              title: 'Uang saku',
              meta: 'Bank · Kiriman · 08.00',
              amount: 'Rp500.000',
              type: AppTransactionType.income,
            ),
            const SizedBox(height: AppSpace.s16),
            for (final type in AppBannerType.values) ...[
              AppBanner(
                type: type,
                title: 'Kamu sedang offline',
                body: '3 perubahan akan disinkron saat online',
                actionLabel: 'Coba lagi',
                onAction: () {},
              ),
              const SizedBox(height: AppSpace.s12),
            ],
            const _Section('Login · Kunci'),
            Row(
              spacing: AppSpace.s8,
              children: [
                for (final state in AppCodeCellState.values)
                  Expanded(
                    child: AppCodeCell(state: state, digit: '4'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.s16),
            const Row(
              spacing: AppSpace.s16,
              children: [
                AppLogoMark(),
                AppLogoMark(size: AppLogoMarkSize.large),
                AppPinDots(filled: 2),
                AppPageIndicator(page: 4),
              ],
            ),
            const SizedBox(height: AppSpace.s16),
            AppKeypad(onDigit: (_) {}, onDelete: () {}, onFingerprint: () {}),
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
