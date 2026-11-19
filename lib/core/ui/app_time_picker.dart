import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';

/// Time Picker dari Figma (Components [09], node 49:309): pemilih jam gaya
/// roda. Angka tengah = nilai terpilih, atas/bawah = sebelum/sesudah.
/// Dibangun sendiri, bukan `showTimePicker` Material.
///
/// Cara pakai (keputusan Bayu, W2-01): geser kolom naik/turun untuk
/// mengganti angka, atau ketuk angka atas/bawah. Tanpa animasi gulir.
class AppTimePicker extends StatelessWidget {
  const AppTimePicker({
    super.key,
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _highlightHeight = 56;

  /// 0–23.
  final int hour;

  /// 0–59.
  final int minute;

  /// Dipanggil dengan jam dan menit baru.
  final void Function(int hour, int minute) onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 0,
          right: 0,
          child: Container(
            height: _highlightHeight,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.item),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: AppSpace.s16,
            children: [
              _WheelColumn(
                value: hour,
                count: 24,
                semanticLabel: 'Jam',
                onChanged: (value) => onChanged(value, minute),
              ),
              Text(
                '.',
                style: AppText.headingLarge.copyWith(color: AppColors.white),
              ),
              _WheelColumn(
                value: minute,
                count: 60,
                semanticLabel: 'Menit',
                onChanged: (value) => onChanged(hour, value),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Satu kolom roda: nilai sebelum (abu), terpilih (putih besar), sesudah
/// (abu). Nilainya berputar: setelah 23 kembali ke 00.
class _WheelColumn extends StatefulWidget {
  const _WheelColumn({
    required this.value,
    required this.count,
    required this.semanticLabel,
    required this.onChanged,
  });

  final int value;
  final int count;
  final String semanticLabel;
  final ValueChanged<int> onChanged;

  @override
  State<_WheelColumn> createState() => _WheelColumnState();
}

class _WheelColumnState extends State<_WheelColumn> {
  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _width = 72;

  /// Jarak geser untuk satu langkah: tinggi baris abu + jarak antarbaris.
  static const double _dragStep = 28 + AppSpace.s8;

  /// Nilai saat jari mulai menyentuh, dan total geser sejak itu. Langkah
  /// dihitung dari total geser, bukan dari nilai terakhir, supaya satu
  /// gerakan panjang tetap maju beberapa langkah.
  int _startValue = 0;
  double _dragged = 0;
  int _appliedSteps = 0;

  int _wrap(int value) => value % widget.count;

  String _label(int value) => _wrap(value).toString().padLeft(2, '0');

  void _step(int delta) => widget.onChanged(_wrap(widget.value + delta));

  void _onDragStart(DragStartDetails details) {
    _startValue = widget.value;
    _dragged = 0;
    _appliedSteps = 0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragged += details.delta.dy;
    // Geser ke atas = angka berikutnya naik ke tengah.
    final steps = (-_dragged / _dragStep).truncate();
    if (steps != _appliedSteps) {
      _appliedSteps = steps;
      widget.onChanged(_wrap(_startValue + steps));
    }
  }

  @override
  Widget build(BuildContext context) {
    final side = AppText.headingMedium.copyWith(color: AppColors.gray);

    return Semantics(
      label: widget.semanticLabel,
      value: _label(widget.value),
      increasedValue: _label(widget.value + 1),
      decreasedValue: _label(widget.value - 1),
      onIncrease: () => _step(1),
      onDecrease: () => _step(-1),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Hitung gerakan sejak jari menyentuh, termasuk ambang mulai geser.
        dragStartBehavior: DragStartBehavior.down,
        onVerticalDragStart: _onDragStart,
        onVerticalDragUpdate: _onDragUpdate,
        child: SizedBox(
          width: _width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.s8,
            children: [
              GestureDetector(
                onTap: () => _step(-1),
                child: Text(_label(widget.value - 1), style: side),
              ),
              Text(
                _label(widget.value),
                style: AppText.headingLarge.copyWith(color: AppColors.white),
              ),
              GestureDetector(
                onTap: () => _step(1),
                child: Text(_label(widget.value + 1), style: side),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
