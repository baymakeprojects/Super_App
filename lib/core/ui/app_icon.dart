import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';

/// Daftar ikon dari Figma Components [01] Ikon (node 5:7).
///
/// Nama mengikuti nama komponen Figma (`Icon/Arrow Up Right` →
/// [AppIcons.arrowUpRight]). File SVG-nya ada di `assets/icons/`.
enum AppIcons {
  // Dari portofolio.
  menu('menu'),
  close('close'),
  arrowRight('arrow_right'),
  arrowLeft('arrow_left'),
  arrowUpRight('arrow_up_right'),
  arrowDown('arrow_down'),
  check('check'),
  plus('plus'),
  refresh('refresh'),
  download('download'),
  copy('copy'),
  external('external'),
  search('search'),

  // Baru untuk app.
  home('home'),
  task('task'),
  calendar('calendar'),
  wallet('wallet'),
  timer('timer'),
  flame('flame'),
  note('note'),
  book('book'),
  learn('learn'),
  folder('folder'),
  chart('chart'),
  settings('settings'),
  fingerprint('fingerprint'),
  bell('bell'),
  user('user'),
  grid('grid'),
  clock('clock'),
  edit('edit'),
  trash('trash'),
  lock('lock'),
  chevronRight('chevron_right'),
  chevronDown('chevron_down'),
  files('files'),
  upload('upload'),
  image('image'),
  scan('scan');

  const AppIcons(this.fileName);

  final String fileName;

  String get assetPath => 'assets/icons/$fileName.svg';
}

/// Ikon garis Figma (24px, stroke 1,5). Satu file SVG dipakai untuk
/// semua warna: warnanya diganti lewat [color].
///
/// Jangan memakai Material Icons atau Cupertino Icons sebagai gantinya.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.color = AppColors.white,
    this.size = defaultSize,
    this.semanticLabel,
  });

  /// Ukuran ikon di Figma.
  static const double defaultSize = 24;

  final AppIcons icon;

  /// Warna garis. Bawaan White, sama seperti komponen Figma.
  final Color color;

  /// Ukuran sisi ikon. Garis ikut membesar atau mengecil.
  final double size;

  /// Teks untuk pembaca layar. Kosongkan untuk ikon hiasan.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      icon.assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
