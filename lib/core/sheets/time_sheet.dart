import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';

/// Jam terpilih di P02.
typedef PickedTime = ({int hour, int minute});

/// Buka P02 Pilih jam (Figma 50:393). Dipakai 15 Tugas baru dan
/// 17 Transaksi baru. Hasilnya `null` kalau dibatalkan.
Future<PickedTime?> showTimeSheet({
  required BuildContext context,
  required PickedTime selected,
  required String subtitle,
}) {
  return showAppBottomSheet<PickedTime>(
    context: context,
    builder: (_) => TimeSheet(selected: selected, subtitle: subtitle),
  );
}

/// Isi P02: roda jam, chip "Cepat" (07.00, 12.00, 17.00, 23.59), lalu
/// Batal + Pilih.
class TimeSheet extends StatefulWidget {
  const TimeSheet({super.key, required this.selected, required this.subtitle});

  final PickedTime selected;

  /// Keterangan di bawah judul, misalnya "Jam deadline · Jum, 6 Nov".
  final String subtitle;

  @override
  State<TimeSheet> createState() => _TimeSheetState();
}

class _TimeSheetState extends State<TimeSheet> {
  /// Jam cepat, disalin dari Figma.
  static const List<PickedTime> _quick = [
    (hour: 7, minute: 0),
    (hour: 12, minute: 0),
    (hour: 17, minute: 0),
    (hour: 23, minute: 59),
  ];

  late PickedTime _selected = widget.selected;

  static String _label(PickedTime time) =>
      '${_two(time.hour)}.${_two(time.minute)}';

  static String _two(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: 'Pilih jam',
      subtitle: widget.subtitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.s16,
        children: [
          AppTimePicker(
            hour: _selected.hour,
            minute: _selected.minute,
            onChanged: (hour, minute) =>
                setState(() => _selected = (hour: hour, minute: minute)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.s8,
            children: [
              AppLabelText(
                'Cepat',
                style: AppText.labelMedium.copyWith(color: AppColors.lightGray),
              ),
              Wrap(
                spacing: AppSpace.s8,
                runSpacing: AppSpace.s8,
                children: [
                  for (final time in _quick)
                    AppChip(
                      label: _label(time),
                      selected: time == _selected,
                      onTap: () => setState(() => _selected = time),
                    ),
                ],
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
          onPressed: () => Navigator.of(context).pop(_selected),
        ),
      ],
    );
  }
}
