import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';

/// Peraga halaman Foundations (Figma node 4:4, 1280×3175) untuk golden test.
///
/// Hanya ada di `test/`: menurut design-notes, frame specimen tidak ikut
/// dibangun di app. Isinya dibangun dari token, jadi kalau token berubah,
/// golden ikut berubah dan bisa dibandingkan lagi dengan Figma.
class FoundationsSheet extends StatelessWidget {
  const FoundationsSheet({super.key});

  /// Ukuran frame Foundations di Figma.
  static const Size frameSize = Size(1280, 3175);

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.primary,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          _Spec.pageSide,
          _Spec.pageTop,
          _Spec.pageSide,
          _Spec.pageTop,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: _Spec.sectionGap,
          children: [
            _PageHeader(),
            _ColorSection(),
            _TypeSection(),
            _SpacingSection(),
          ],
        ),
      ),
    );
  }
}

/// Ukuran kotak peraga yang hanya ada di halaman Foundations
/// (bukan token app).
abstract final class _Spec {
  static const double pageSide = 64;
  static const double pageTop = 72;
  static const double sectionGap = 64;
  static const double headerGap = 14;
  static const double descWidth = 760;
  static const double specimenRadius = 14;
  static const double swatchWidth = 276;
  static const double swatchColorHeight = 88;
  static const double swatchInfoTop = 14;
  static const double swatchDescWidth = 244;
  static const double gradientHeight = 96;
  static const double typeRowPadding = 18;
  static const double typeMetaWidth = 260;
  static const double spacingBarHeight = 40;
  static const double spacingGap = 40;
  static const double itemLabelGap = 10;
  static const double radiusShape = 96;
}

TextStyle _style(TextStyle base, Color color) => base.copyWith(color: color);

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: _Spec.headerGap,
      children: [
        Text(
          '[ Super App — Foundations ]'.toUpperCase(),
          style: _style(AppText.labelMedium, AppColors.accentText),
        ),
        Text(
          'Fondasi desain',
          style: _style(AppText.headingLarge, AppColors.white),
        ),
        SizedBox(
          width: _Spec.descWidth,
          child: Text(
            'Warna dark mode, font, dan sudut diambil dari file Portofolio. '
            'Semua warna tersimpan sebagai variabel di koleksi Palette '
            '(mode Dark): ubah nilainya di sana, semua komponen dan layar '
            'ikut berubah.',
            style: _style(AppText.bodyMedium, AppColors.lightGray),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.description});

  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.s8,
      children: [
        Text(
          label.toUpperCase(),
          style: _style(AppText.labelMedium, AppColors.accentText),
        ),
        SizedBox(
          width: _Spec.descWidth,
          child: Text(
            description,
            style: _style(AppText.bodyMedium, AppColors.lightGray),
          ),
        ),
      ],
    );
  }
}

class _SubLabel extends StatelessWidget {
  const _SubLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: _style(AppText.labelSmall, AppColors.gray),
    );
  }
}

typedef _SwatchData = ({String name, String hex, String usage, Color color});

const List<_SwatchData> _coreSwatches = [
  (
    name: 'Primary',
    hex: '#000000',
    usage: 'Latar halaman',
    color: AppColors.primary,
  ),
  (
    name: 'Surface/Raised',
    hex: '#0D0D0D',
    usage: 'Kartu & panel',
    color: AppColors.surfaceRaised,
  ),
  (
    name: 'Surface/Card',
    hex: '#1E1E1E',
    usage: 'Kartu menonjol, track progress',
    color: AppColors.surfaceCard,
  ),
  (
    name: 'Dark Gray',
    hex: '#333333',
    usage: 'Garis & border',
    color: AppColors.darkGray,
  ),
  (
    name: 'Gray',
    hex: '#8A8A8A',
    usage: 'Label, keterangan, placeholder',
    color: AppColors.gray,
  ),
  (
    name: 'Light Gray',
    hex: '#A7A7A7',
    usage: 'Teks sekunder',
    color: AppColors.lightGray,
  ),
  (name: 'White', hex: '#F9F9F9', usage: 'Teks utama', color: AppColors.white),
  (
    name: 'Branding Orange',
    hex: '#E85002',
    usage: 'Tombol utama, ikon aktif, highlight',
    color: AppColors.brandingOrange,
  ),
];

const List<_SwatchData> _specialSwatches = [
  (
    name: 'Gradient/Sand',
    hex: '#D9C3AB',
    usage: 'Gradasi, sorotan',
    color: AppColors.gradientSand,
  ),
  (
    name: 'Gradient/Flame',
    hex: '#F16001',
    usage: 'Gradasi, tombol hover',
    color: AppColors.gradientFlame,
  ),
  (
    name: 'Gradient/Red',
    hex: '#C10801',
    usage: 'Gradasi, tombol ditekan',
    color: AppColors.gradientRed,
  ),
  (
    name: 'On Accent',
    hex: '#000000',
    usage: 'Teks & ikon di atas oranye',
    color: AppColors.onAccent,
  ),
  (
    name: 'Accent Text',
    hex: '#E85002',
    usage: 'Teks oranye kecil',
    color: AppColors.accentText,
  ),
];

const List<_SwatchData> _statusSwatches = [
  (
    name: 'Status/Success',
    hex: '#4FAE68',
    usage: 'Pemasukan, selesai, kebiasaan tercentang',
    color: AppColors.success,
  ),
  (
    name: 'Status/Warning',
    hex: '#E3C46A',
    usage: 'Deadline dekat, budget hampir habis',
    color: AppColors.warning,
  ),
  (
    name: 'Status/Danger',
    hex: '#FF5A5F',
    usage: 'Pengeluaran, terlambat, error',
    color: AppColors.danger,
  ),
];

class _ColorSection extends StatelessWidget {
  const _ColorSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.s24,
      children: [
        const _SectionHeader(
          label: '[01] Warna',
          description:
              'Diambil dari mode Dark portofolio. Tiga warna status '
              'ditambahkan untuk kebutuhan app: dua dari palet planet '
              'portofolio, satu warna merah baru.',
        ),
        const _SubLabel('Inti'),
        const _SwatchGrid(_coreSwatches),
        const _SubLabel('Gradasi & khusus'),
        const _SwatchGrid(_specialSwatches),
        const _SubLabel('Status (baru untuk app)'),
        const _SwatchGrid(_statusSwatches),
        const _SubLabel('Gradient/Branding — paint style'),
        Container(
          height: _Spec.gradientHeight,
          decoration: BoxDecoration(
            gradient: AppColors.gradientBranding,
            borderRadius: BorderRadius.circular(_Spec.specimenRadius),
          ),
        ),
      ],
    );
  }
}

class _SwatchGrid extends StatelessWidget {
  const _SwatchGrid(this.swatches);

  final List<_SwatchData> swatches;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.s16,
      runSpacing: AppSpace.s16,
      children: [for (final swatch in swatches) _Swatch(swatch)],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.data);

  final _SwatchData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _Spec.swatchWidth,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.darkGray),
        borderRadius: BorderRadius.circular(_Spec.specimenRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _Spec.swatchColorHeight,
            child: ColoredBox(color: data.color),
          ),
          ColoredBox(
            color: AppColors.surfaceRaised,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s16,
                _Spec.swatchInfoTop,
                AppSpace.s16,
                AppSpace.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.s4,
                children: [
                  Text(
                    data.name,
                    style: _style(AppText.titleMedium, AppColors.white),
                  ),
                  Text(
                    data.hex.toUpperCase(),
                    style: _style(AppText.labelSmall, AppColors.lightGray),
                  ),
                  SizedBox(
                    width: _Spec.swatchDescWidth,
                    child: Text(
                      data.usage,
                      style: _style(AppText.bodySmall, AppColors.gray),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

typedef _TypeData = ({
  String name,
  String meta,
  String sample,
  TextStyle style,
  bool caps,
});

const List<_TypeData> _typeScale = [
  (
    name: 'Display/Large',
    meta: 'Doto Black · 48/48 · −1',
    sample: 'Rp1.250.000',
    style: AppText.displayLarge,
    caps: false,
  ),
  (
    name: 'Display/Medium',
    meta: 'Doto Black · 36/38',
    sample: '12 hari',
    style: AppText.displayMedium,
    caps: false,
  ),
  (
    name: 'Display/Small',
    meta: 'Doto Black · 28/30',
    sample: '3/5',
    style: AppText.displaySmall,
    caps: false,
  ),
  (
    name: 'Heading/Large',
    meta: 'Geist Medium · 28/34 · −0.8',
    sample: 'Halo, Bayu',
    style: AppText.headingLarge,
    caps: false,
  ),
  (
    name: 'Heading/Medium',
    meta: 'Geist Medium · 22/28 · −0.3',
    sample: 'Tugas hari ini',
    style: AppText.headingMedium,
    caps: false,
  ),
  (
    name: 'Heading/Small',
    meta: 'Geist Medium · 18/24 · −0.2',
    sample: 'Pemrograman Mobile',
    style: AppText.headingSmall,
    caps: false,
  ),
  (
    name: 'Title/Medium',
    meta: 'Geist Medium · 16/22',
    sample: 'Kerjakan laporan praktikum',
    style: AppText.titleMedium,
    caps: false,
  ),
  (
    name: 'Body/Large',
    meta: 'Geist Regular · 16/24',
    sample: 'Catatan pertemuan minggu ini dan tugas yang harus dikumpulkan.',
    style: AppText.bodyLarge,
    caps: false,
  ),
  (
    name: 'Body/Medium',
    meta: 'Geist Regular · 14/20',
    sample: 'Catatan pertemuan minggu ini dan tugas yang harus dikumpulkan.',
    style: AppText.bodyMedium,
    caps: false,
  ),
  (
    name: 'Body/Small',
    meta: 'Geist Regular · 12/16',
    sample: 'Diperbarui 5 menit lalu',
    style: AppText.bodySmall,
    caps: false,
  ),
  (
    name: 'Label/Large',
    meta: 'Geist Mono SemiBold · 13/18 · +1 · kapital',
    sample: 'Simpan tugas →',
    style: AppText.labelLarge,
    caps: true,
  ),
  (
    name: 'Label/Medium',
    meta: 'Geist Mono Regular · 11/16 · +1.5 · kapital',
    sample: '[01] Tugas',
    style: AppText.labelMedium,
    caps: true,
  ),
  (
    name: 'Label/Small',
    meta: 'Geist Mono Regular · 10/14 · +1.5 · kapital',
    sample: 'Jumat · 08.00',
    style: AppText.labelSmall,
    caps: true,
  ),
];

class _TypeSection extends StatelessWidget {
  const _TypeSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.s24,
      children: [
        const _SectionHeader(
          label: '[02] Tipografi',
          description:
              'Tiga font dari portofolio dengan skala ukuran untuk layar HP: '
              'Doto untuk angka besar ala dot-matrix, Geist untuk teks, '
              'Geist Mono untuk label dan tombol.',
        ),
        Column(children: [for (final type in _typeScale) _TypeRow(type)]),
      ],
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow(this.data);

  final _TypeData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: _Spec.typeRowPadding),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.darkGray)),
      ),
      child: Row(
        spacing: AppSpace.s32,
        children: [
          SizedBox(
            width: _Spec.typeMetaWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.s4,
              children: [
                Text(
                  data.name.toUpperCase(),
                  style: _style(AppText.labelSmall, AppColors.lightGray),
                ),
                Text(
                  data.meta,
                  style: _style(AppText.bodySmall, AppColors.gray),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              data.caps ? data.sample.toUpperCase() : data.sample,
              style: _style(data.style, AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpacingSection extends StatelessWidget {
  const _SpacingSection();

  static const List<double> _spaces = [
    AppSpace.s4,
    AppSpace.s8,
    AppSpace.s12,
    AppSpace.s16,
    AppSpace.s20,
    AppSpace.s24,
    AppSpace.s32,
  ];

  static const List<(String, double)> _radii = [
    ('Input · 10', AppRadius.input),
    ('Button · 12', AppRadius.button),
    ('Card · 20', AppRadius.card),
    ('Full · 999', AppRadius.full),
  ];

  @override
  Widget build(BuildContext context) {
    final labelStyle = _style(AppText.labelSmall, AppColors.lightGray);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.s24,
      children: [
        const _SectionHeader(
          label: '[03] Spasi & sudut',
          description:
              'Spasi kelipatan 4. Sudut mengikuti portofolio: input 10, '
              'tombol 12, kartu 20, chip berbentuk pil.',
        ),
        const _SubLabel('Spasi'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: _Spec.spacingGap,
          children: [
            for (final space in _spaces)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: _Spec.itemLabelGap,
                children: [
                  Container(
                    width: space,
                    height: _Spec.spacingBarHeight,
                    color: AppColors.brandingOrange,
                  ),
                  Text(space.toInt().toString(), style: labelStyle),
                ],
              ),
          ],
        ),
        const _SubLabel('Sudut'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpace.s24,
          children: [
            for (final (label, radius) in _radii)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: _Spec.itemLabelGap,
                children: [
                  Container(
                    width: _Spec.radiusShape,
                    height: _Spec.radiusShape,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      border: Border.all(color: AppColors.darkGray),
                      borderRadius: BorderRadius.circular(radius),
                    ),
                  ),
                  Text(label.toUpperCase(), style: labelStyle),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
