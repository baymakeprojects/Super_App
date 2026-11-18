import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_icon.dart';
import 'package:super_app/core/ui/app_nav_item.dart';

/// Satu tab Bottom Nav: ikon dan label dari Figma.
typedef AppBottomNavTab = ({AppIcons icon, String label});

/// Bottom Nav dari Figma (Components [05], node 7:46): 5 tab tetap,
/// garis atas Dark Gray, latar hitam.
///
/// Di bawah padding 12 dari Figma ditambah tinggi gesture bar sistem
/// (safe area), supaya tab tidak tertutup bar navigasi Android.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// Urutan tab sesuai Figma. Indeks 0 = Beranda.
  static const List<AppBottomNavTab> tabs = [
    (icon: AppIcons.home, label: 'Beranda'),
    (icon: AppIcons.task, label: 'Tugas'),
    (icon: AppIcons.calendar, label: 'Kuliah'),
    (icon: AppIcons.wallet, label: 'Keuangan'),
    (icon: AppIcons.grid, label: 'Lainnya'),
  ];

  static const double _sidePadding = AppSpace.s8;
  static const double _borderWidth = 1;

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final systemBottom = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.only(
        left: _sidePadding,
        right: _sidePadding,
        bottom: AppSpace.s12 + systemBottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        border: Border(
          top: BorderSide(color: AppColors.darkGray, width: _borderWidth),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: AppNavItem(
                icon: tabs[i].icon,
                label: tabs[i].label,
                active: i == currentIndex,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}
