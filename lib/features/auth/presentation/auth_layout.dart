import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';

/// Kerangka layar masuk dan kunci (00e, 00f, 01, G1): isi berpadding
/// 24/32, bagian atas dan bawah dipisah sejauh mungkin (justify-between).
///
/// Isi bisa digulir kalau keyboard muncul, tapi tetap mengisi tinggi
/// layar saat keyboard tertutup.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.children});

  /// Bagian layar dari atas ke bawah (Greeting, Sensor, Actions, ...).
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: FillViewport(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s24,
              vertical: AppSpace.s32,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// Isi yang minimal setinggi layar dan bisa digulir kalau lebih tinggi
/// (misalnya saat keyboard muncul). Column di dalamnya dengan
/// `spaceBetween` membagi sisa tinggi layar seperti di Figma.
class FillViewport extends StatelessWidget {
  const FillViewport({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }
}

/// Blok sapaan (Greeting): label "[ Super App ]", judul Doto besar, dan
/// keterangan abu selebar 300.
class AuthGreeting extends StatelessWidget {
  const AuthGreeting({super.key, required this.title, required this.body});

  /// Lebar teks keterangan di Figma (tetap, bukan variabel).
  static const double _bodyWidth = 300;

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.s16,
      children: [
        AppLabelText(
          '[ Super App ]',
          style: AppText.labelMedium.copyWith(color: AppColors.accentText),
        ),
        Text(
          title,
          style: AppText.displayLarge.copyWith(color: AppColors.white),
        ),
        SizedBox(
          width: _bodyWidth,
          child: Text(
            body,
            style: AppText.bodyLarge.copyWith(color: AppColors.lightGray),
          ),
        ),
      ],
    );
  }
}

/// Judul sapaan 01 dan G1: "Halo," lalu nama di baris kedua. Tanpa nama
/// (login email tidak memberi nama, F-14): "Halo" saja, sama seperti
/// Beranda (F-45).
String greetingTitle(String? name) => name == null ? 'Halo' : 'Halo,\n$name';

/// Baris kecil di bawah layar 01 dan G1: ikon Refresh 14 dan teks abu.
class AuthSyncLine extends StatelessWidget {
  const AuthSyncLine(this.text, {super.key});

  static const double _iconSize = 14;
  static const double _gap = 6;

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: _gap,
      children: [
        const AppIcon(AppIcons.refresh, color: AppColors.gray, size: _iconSize),
        AppLabelText(
          text,
          style: AppText.labelSmall.copyWith(color: AppColors.gray),
        ),
      ],
    );
  }
}
