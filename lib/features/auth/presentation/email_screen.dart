import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/routes.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/features/auth/application/login_controller.dart';
import 'package:super_app/features/auth/presentation/auth_layout.dart';

/// 00e Masuk dengan email (Figma 230:5209) beserta keadaannya: email tidak
/// valid (230:5235), mengirim kode (230:5261), gagal kirim kode (230:5287).
class EmailScreen extends ConsumerStatefulWidget {
  const EmailScreen({super.key});

  @override
  ConsumerState<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends ConsumerState<EmailScreen> {
  late final TextEditingController _email = TextEditingController(
    text: ref.read(loginControllerProvider)?.email,
  );
  final FocusNode _focus = FocusNode();

  bool _invalid = false;
  bool _sending = false;
  bool _failed = false;

  @override
  void dispose() {
    _email.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!isValidEmail(_email.text)) {
      setState(() => _invalid = true);
      return;
    }
    _focus.unfocus();
    setState(() {
      _sending = true;
      _failed = false;
    });
    try {
      await ref.read(loginControllerProvider.notifier).sendCode(_email.text);
    } on Object {
      if (mounted) {
        setState(() {
          _sending = false;
          _failed = true;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() => _sending = false);
    await context.push(AppRoutes.masukKode);
  }

  @override
  Widget build(BuildContext context) {
    final String buttonLabel;
    if (_sending) {
      buttonLabel = 'Mengirim kode…';
    } else if (_failed) {
      buttonLabel = 'Coba lagi →';
    } else {
      buttonLabel = 'Kirim kode →';
    }

    return AuthScaffold(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.s32,
          children: [
            const AuthGreeting(
              title: 'Masuk',
              body:
                  'Masukkan email kamu. Kami kirim kode 6 digit untuk masuk, '
                  'tanpa password.',
            ),
            AppInput(
              label: 'Email',
              placeholder: 'bayu@email.com',
              controller: _email,
              focusNode: _focus,
              autofocus: true,
              enabled: !_sending,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.send,
              errorText: _invalid
                  ? 'Format email belum benar. Contoh: nama@email.com'
                  : null,
              onChanged: (_) {
                if (_invalid || _failed) {
                  setState(() {
                    _invalid = false;
                    _failed = false;
                  });
                }
              },
              onSubmitted: (_) => _send(),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.s16,
          children: [
            if (_failed)
              const AppBanner(
                type: AppBannerType.danger,
                title: 'Kode belum terkirim',
                body: 'Periksa koneksi internet, lalu coba lagi.',
              ),
            AppButton(label: buttonLabel, onPressed: _sending ? null : _send),
            Center(
              child: AppLabelText(
                'Akun baru dibuat otomatis',
                style: AppText.labelSmall.copyWith(color: AppColors.gray),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
