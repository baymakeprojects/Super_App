import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_day_cell.dart';
import 'package:super_app/core/ui/app_icon.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Date Picker dari Figma (Components [09], node 49:191): kalender satu
/// bulan, Senin di awal minggu. Dibangun sendiri, bukan `showDatePicker`
/// Material (design-notes §4).
///
/// Selalu 6 baris minggu supaya tinggi pop-up tidak berubah saat pindah
/// bulan (keputusan Bayu, W2-01).
class AppDatePicker extends StatefulWidget {
  const AppDatePicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.today,
    this.initialMonth,
  });

  /// Tanggal terpilih. `null` = belum ada.
  final DateTime? selected;

  final ValueChanged<DateTime> onSelected;

  /// Hari ini (untuk tes). Bawaan: tanggal di HP.
  final DateTime? today;

  /// Bulan yang tampil pertama. Bawaan: bulan [selected] atau [today].
  final DateTime? initialMonth;

  @override
  State<AppDatePicker> createState() => _AppDatePickerState();
}

class _AppDatePickerState extends State<AppDatePicker> {
  static const int _weeks = 6;
  static const int _daysPerWeek = 7;

  /// Inisial hari Senin–Minggu, disalin dari Figma.
  static const List<String> _weekdays = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

  static const List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  late DateTime _month;

  DateTime get _today => widget.today ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    final start = widget.initialMonth ?? widget.selected ?? _today;
    _month = DateTime(start.year, start.month);
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  static bool _sameDay(DateTime a, DateTime? b) =>
      b != null && a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    // Senin pertama yang tampil (bisa di bulan sebelumnya).
    final firstOfMonth = DateTime(_month.year, _month.month);
    final leading = firstOfMonth.weekday - DateTime.monday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s12,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_months[_month.month - 1]} ${_month.year}',
              style: AppText.titleMedium.copyWith(color: AppColors.white),
            ),
            Row(
              spacing: AppSpace.s8,
              children: [
                _NavButton(
                  icon: AppIcons.arrowLeft,
                  semanticLabel: 'Bulan sebelumnya',
                  onTap: () => _changeMonth(-1),
                ),
                _NavButton(
                  icon: AppIcons.arrowRight,
                  semanticLabel: 'Bulan berikutnya',
                  onTap: () => _changeMonth(1),
                ),
              ],
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final weekday in _weekdays)
              SizedBox(
                width: AppDayCell.size,
                height: AppSpace.s16,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: AppLabelText(
                    weekday,
                    style: AppText.labelSmall.copyWith(color: AppColors.gray),
                  ),
                ),
              ),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpace.s4,
          children: [
            for (var week = 0; week < _weeks; week++)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var day = 0; day < _daysPerWeek; day++)
                    _cell(
                      DateTime(
                        _month.year,
                        _month.month,
                        1 - leading + week * _daysPerWeek + day,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _cell(DateTime date) {
    final inMonth = date.month == _month.month;
    final state = !inMonth
        ? AppDayCellState.muted
        : _sameDay(date, widget.selected)
        ? AppDayCellState.selected
        : _sameDay(date, _today)
        ? AppDayCellState.today
        : AppDayCellState.normal;

    return AppDayCell(
      day: '${date.day}',
      state: state,
      onTap: inMonth ? () => widget.onSelected(date) : null,
    );
  }
}

/// Tombol bulat 32px untuk pindah bulan.
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _size = 32;
  static const double _iconSize = 16;
  static const double _borderWidth = 1;

  final AppIcons icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: _size,
          height: _size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.darkGray, width: _borderWidth),
          ),
          child: AppIcon(icon, size: _iconSize, color: AppColors.lightGray),
        ),
      ),
    );
  }
}
