import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Keadaan Input di Figma. Di layar, keadaan muncul sendiri:
/// Focus saat diketuk, Error saat [AppInput.errorText] diisi.
enum AppInputState { normal, focus, error }

/// Input dari Figma (Components [03], node 6:51): label kecil kapital di
/// atas kolom, sudut 10. Focus: garis dan label oranye. Error: garis,
/// label, dan pesan merah di bawah kolom.
class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    required this.label,
    this.placeholder,
    this.errorText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofocus = false,
    this.enabled = true,
    this.previewState,
  });

  /// Label di atas kolom. Dikapitalkan otomatis.
  final String label;

  /// Teks contoh abu saat kolom kosong.
  final String? placeholder;

  /// Pesan error di bawah kolom. Diisi = keadaan Error.
  final String? errorText;

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final bool enabled;

  /// Paksa tampilan keadaan tertentu. Hanya untuk katalog dan golden test;
  /// di layar biarkan `null`.
  final AppInputState? previewState;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  static const double _borderWidth = 1;

  FocusNode? _ownFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AppInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onFocusChange);
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  AppInputState get _state {
    if (widget.previewState case final state?) return state;
    if (widget.errorText != null) return AppInputState.error;
    if (_focusNode.hasFocus) return AppInputState.focus;
    return AppInputState.normal;
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final (labelColor, borderColor) = switch (state) {
      AppInputState.normal => (AppColors.lightGray, AppColors.darkGray),
      AppInputState.focus => (AppColors.accentText, AppColors.brandingOrange),
      AppInputState.error => (AppColors.danger, AppColors.danger),
    };
    final errorText = widget.errorText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s8,
      children: [
        AppLabelText(
          widget.label,
          style: AppText.labelMedium.copyWith(color: labelColor),
        ),
        GestureDetector(
          onTap: widget.enabled ? _focusNode.requestFocus : null,
          child: Container(
            padding: const EdgeInsets.all(AppSpace.s16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              border: Border.all(color: borderColor, width: _borderWidth),
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            // TextField hanya dipakai sebagai mesin ketik; seluruh tampilan
            // (garis, label, warna) dari token, bukan gaya Material.
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                inputFormatters: widget.inputFormatters,
                autofocus: widget.autofocus,
                enabled: widget.enabled,
                style: AppText.bodyLarge.copyWith(color: AppColors.white),
                cursorColor: AppColors.brandingOrange,
                decoration: InputDecoration.collapsed(
                  hintText: widget.placeholder,
                  hintStyle: AppText.bodyLarge.copyWith(color: AppColors.gray),
                ),
              ),
            ),
          ),
        ),
        if (state == AppInputState.error && errorText != null)
          Text(
            errorText,
            style: AppText.bodySmall.copyWith(color: AppColors.danger),
          ),
      ],
    );
  }
}
