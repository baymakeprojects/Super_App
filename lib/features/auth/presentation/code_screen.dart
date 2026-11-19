import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/features/auth/application/login_controller.dart';
import 'package:super_app/features/auth/presentation/auth_layout.dart';

/// 00f Masukkan kode (Figma 231:5271) beserta keadaannya: kode salah
/// (231:5310), kode kedaluwarsa (231:5349), memeriksa kode (231:5388).
class CodeScreen extends ConsumerStatefulWidget {
  const CodeScreen({super.key});

  /// Jumlah digit kode.
  static const int length = 6;

  @override
  ConsumerState<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends ConsumerState<CodeScreen> {
  final TextEditingController _code = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _ticker;

  bool _checking = false;
  bool _resending = false;
  CodeError? _error;

  /// Email terakhir, tetap tampil walau alur login sudah selesai.
  String _email = '';

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  /// Hitung mundur "Kirim ulang dalam 00.42": layar digambar ulang tiap
  /// detik selama hitung mundur berjalan, lalu berhenti.
  void _tickWhile(bool counting) {
    if (!counting) {
      _ticker?.cancel();
      _ticker = null;
    } else {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    _focus.unfocus();
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      await ref.read(loginControllerProvider.notifier).verifyCode(_code.text);
    } on CodeCheckException catch (error) {
      if (mounted) {
        setState(() {
          _checking = false;
          _error = error.error;
        });
      }
      return;
    }
    // Berhasil: router pindah ke Beranda.
    if (mounted) setState(() => _checking = false);
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
      _code.clear();
    });
    try {
      await ref.read(loginControllerProvider.notifier).resendCode();
    } on Object {
      if (mounted) setState(() => _error = CodeError.network);
    }
    if (mounted) setState(() => _resending = false);
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(loginControllerProvider);
    if (flow != null) _email = flow.email;
    final now = ref.watch(clockProvider)();
    final resendIn = flow == null
        ? Duration.zero
        : flow.sentAt.add(resendCooldown).difference(now);
    _tickWhile(resendIn > Duration.zero);

    final code = _code.text;
    final error = _error;
    final rejected = error == CodeError.wrong || error == CodeError.expired;
    final canSubmit =
        code.length == CodeScreen.length &&
        !_checking &&
        error != CodeError.expired;

    AppCodeCellState cellState(int index) {
      if (rejected) return AppCodeCellState.error;
      if (index < code.length) return AppCodeCellState.filled;
      if (index == code.length && _focus.hasFocus) {
        return AppCodeCellState.focus;
      }
      return AppCodeCellState.empty;
    }

    final cells = Row(
      spacing: AppSpace.s8,
      children: [
        for (var i = 0; i < CodeScreen.length; i++)
          Expanded(
            child: AppCodeCell(
              state: cellState(i),
              digit: i < code.length ? code[i] : '',
            ),
          ),
      ],
    );

    final link = AppText.labelMedium.copyWith(color: AppColors.accentText);
    final Widget resend;
    if (error == CodeError.expired || resendIn <= Duration.zero) {
      resend = GestureDetector(
        onTap: _resending ? null : _resend,
        child: AppLabelText('Kirim ulang kode', style: link),
      );
    } else {
      resend = AppLabelText(
        'Kirim ulang dalam ${_countdown(resendIn)}',
        style: AppText.labelSmall.copyWith(color: AppColors.gray),
      );
    }

    return AuthScaffold(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.s32,
          children: [
            AuthGreeting(
              title: 'Cek\nemail',
              body:
                  'Kode 6 digit sudah dikirim ke $_email. '
                  'Berlaku 10 menit.',
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.s12,
              children: [
                AppLabelText(
                  'Kode verifikasi',
                  style: AppText.labelMedium.copyWith(
                    color: rejected ? AppColors.danger : AppColors.lightGray,
                  ),
                ),
                Stack(
                  children: [
                    cells,
                    // Kolom ketik tak terlihat di atas kotak: mengetuk kotak
                    // membuka keyboard angka, dan kode dari email bisa
                    // diisi otomatis.
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0,
                        child: TextField(
                          controller: _code,
                          focusNode: _focus,
                          autofocus: true,
                          enabled: !_checking,
                          keyboardType: TextInputType.number,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          showCursor: false,
                          enableInteractiveSelection: false,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(CodeScreen.length),
                          ],
                          onChanged: (_) => setState(() {
                            if (_error != CodeError.expired) _error = null;
                          }),
                          onSubmitted: (_) {
                            if (canSubmit) unawaited(_verify());
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                if (error != null)
                  Text(
                    _errorText(error),
                    style: AppText.bodySmall.copyWith(color: AppColors.danger),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    resend,
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: AppLabelText('Ganti email', style: link),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        AppButton(
          label: _checking ? 'Memeriksa kode…' : 'Masuk →',
          onPressed: canSubmit ? _verify : null,
        ),
      ],
    );
  }

  static String _errorText(CodeError error) => switch (error) {
    CodeError.wrong => 'Kode salah. Periksa lagi kode di email terbaru.',
    CodeError.expired => 'Kode sudah kedaluwarsa. Minta kode baru.',
    // Belum ada frame untuk offline saat memeriksa kode (F-49): kalimat
    // dari 00e Gagal kirim kode.
    CodeError.network => 'Periksa koneksi internet, lalu coba lagi.',
  };

  /// "00.42": menit.detik.
  static String _countdown(Duration left) {
    final seconds = (left.inMilliseconds / 1000).ceil();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(seconds ~/ 60)}.${two(seconds % 60)}';
  }
}
