import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/core/utils/date_format.dart';

/// Hasil P01. [date] `null` = "Tanpa tanggal" (bukan dibatalkan; batal
/// mengembalikan `null` dari [showDateSheet]).
class PickedDate {
  const PickedDate(this.date);

  final DateTime? date;
}

/// Buka P01 Pilih tanggal (Figma 50:326). Dipakai 15 Tugas baru dan
/// 17 Transaksi baru.
Future<PickedDate?> showDateSheet({
  required BuildContext context,
  required DateTime? selected,
  required DateTime today,
  required String subtitle,
  bool allowNoDate = true,
}) {
  return showAppBottomSheet<PickedDate>(
    context: context,
    builder: (_) => DateSheet(
      selected: selected,
      today: today,
      subtitle: subtitle,
      allowNoDate: allowNoDate,
    ),
  );
}

/// Isi P01: kalender, chip cepat (Hari ini, Besok, Senin depan, Tanpa
/// tanggal), lalu Batal + Pilih. Tanggal baru tersimpan setelah Pilih.
class DateSheet extends StatefulWidget {
  const DateSheet({
    super.key,
    required this.selected,
    required this.today,
    required this.subtitle,
    this.allowNoDate = true,
  });

  final DateTime? selected;
  final DateTime today;

  /// Keterangan di bawah judul, misalnya "Tenggat tugas".
  final String subtitle;

  /// Tampilkan chip "Tanpa tanggal" (form transaksi wajib bertanggal).
  final bool allowNoDate;

  @override
  State<DateSheet> createState() => _DateSheetState();
}

class _DateSheetState extends State<DateSheet> {
  late DateTime? _selected = widget.selected;

  /// Naik setiap chip diketuk, supaya kalender pindah ke bulan tanggal
  /// chip itu (misalnya Senin depan di bulan berikutnya).
  int _jumps = 0;

  DateTime get _today => AppDateFormat.dateOnly(widget.today);

  DateTime get _tomorrow => DateTime(_today.year, _today.month, _today.day + 1);

  /// Senin setelah hari ini; kalau hari ini Senin, Senin minggu depan.
  DateTime get _nextMonday {
    final days = DateTime.daysPerWeek - (_today.weekday - DateTime.monday);
    return DateTime(_today.year, _today.month, _today.day + days);
  }

  bool _isSelected(DateTime date) {
    final selected = _selected;
    return selected != null && AppDateFormat.daysBetween(selected, date) == 0;
  }

  void _jumpTo(DateTime? date) {
    setState(() {
      _selected = date;
      _jumps++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final quick = <(String, DateTime)>[
      ('Hari ini', _today),
      ('Besok', _tomorrow),
      ('Senin depan', _nextMonday),
    ];

    return AppBottomSheet(
      title: 'Pilih tanggal',
      subtitle: widget.subtitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.s16,
        children: [
          AppDatePicker(
            key: ValueKey(_jumps),
            selected: _selected,
            today: _today,
            initialMonth: _selected ?? _today,
            onSelected: (date) => setState(() => _selected = date),
          ),
          Wrap(
            spacing: AppSpace.s8,
            runSpacing: AppSpace.s8,
            children: [
              for (final (label, date) in quick)
                AppChip(
                  label: label,
                  selected: _isSelected(date),
                  onTap: () => _jumpTo(date),
                ),
              if (widget.allowNoDate)
                AppChip(
                  label: 'Tanpa tanggal',
                  selected: _selected == null,
                  onTap: () => _jumpTo(null),
                ),
            ],
          ),
        ],
      ),
      footer: [
        AppButton(
          label: 'Batal',
          style: AppButtonStyle.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: 'Pilih',
          onPressed: () => Navigator.of(context).pop(PickedDate(_selected)),
        ),
      ],
    );
  }
}
