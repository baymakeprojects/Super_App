import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/routes.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';

/// `/intro`: 00a–00d Intro 1–4 (Figma 63:1670, 63:1778, 63:1888, 63:1997)
/// dalam satu halaman yang bisa digeser. "Lanjut →" pindah ke halaman
/// berikutnya; "Lewati" (00a–00c) dan "Mulai sekarang →" (00d) membuka
/// Masuk dengan email.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  static const Duration _slide = Duration(milliseconds: 300);

  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openLogin() => context.push(AppRoutes.masuk);

  void _next() {
    if (_page == _pages.length - 1) {
      _openLogin();
      return;
    }
    _controller.nextPage(duration: _slide, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  for (final (i, page) in _pages.indexed)
                    _IntroPage(
                      page: page,
                      onSkip: i == _pages.length - 1 ? null : _openLogin,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s24,
                AppSpace.s16,
                AppSpace.s24,
                AppSpace.s32,
              ),
              child: Column(
                spacing: AppSpace.s24,
                children: [
                  AppPageIndicator(page: _page + 1, count: _pages.length),
                  AppButton(
                    label: last ? 'Mulai sekarang →' : 'Lanjut →',
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Isi satu halaman intro, teks disalin dari Figma.
class _PageContent {
  const _PageContent({
    required this.label,
    required this.title,
    required this.body,
    required this.illustration,
  });

  final String label;
  final String title;
  final String body;
  final Widget illustration;
}

const List<_PageContent> _pages = [
  _PageContent(
    label: '[01] Selamat datang',
    title: 'Semua urusan kuliah\ndi satu app',
    body:
        'Tugas, jadwal, keuangan, catatan, sampai skripsi. Satu tempat yang '
        'sama di HP dan desktop.',
    illustration: _ModulesIllustration(),
  ),
  _PageContent(
    label: '[02] Kuliah & tugas',
    title: 'Jadwal dan deadline\ntidak kelewat',
    body:
        'Pengingat sebelum kelas mulai dan sebelum deadline. Tugas besar bisa '
        'dipecah jadi sub-tugas kecil.',
    illustration: _StudyIllustration(),
  ),
  _PageContent(
    label: '[03] Keuangan',
    title: 'Uang bulanan\ntetap terkendali',
    body:
        'Catat pengeluaran dalam hitungan detik, atur budget per kategori, dan '
        'diingatkan sebelum tagihan jatuh tempo.',
    illustration: _MoneyIllustration(),
  ),
  _PageContent(
    label: '[04] Aman & sinkron',
    title: 'Terkunci sidik jari,\nsinkron ke desktop',
    body:
        'Hanya kamu yang bisa membuka app. Data tersimpan di cloud dan '
        'otomatis sama di HP dan desktop.',
    illustration: _SecureIllustration(),
  ),
];

/// Bagian halaman yang ikut bergeser: logo + Lewati, ilustrasi, dan teks.
class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.page, required this.onSkip});

  final _PageContent page;

  /// `null` = tanpa "Lewati" (00d).
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBar(onSkip: onSkip),
          page.illustration,
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.s24,
              AppSpace.s8,
              AppSpace.s24,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpace.s12,
              children: [
                AppLabelText(
                  page.label,
                  style: AppText.labelSmall.copyWith(
                    color: AppColors.accentText,
                  ),
                ),
                Text(
                  page.title,
                  style: AppText.headingLarge.copyWith(color: AppColors.white),
                ),
                Text(
                  page.body,
                  style: AppText.bodyLarge.copyWith(color: AppColors.lightGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris atas (63:1682): logo kecil di kiri, "Lewati" di kanan.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSkip});

  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final onSkip = this.onSkip;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s24,
        vertical: AppSpace.s12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            // Figma: 12 di kiri logo.
            padding: const EdgeInsets.only(left: AppSpace.s12),
            child: Row(
              spacing: AppSpace.s12,
              children: [
                const AppLogoMark(),
                AppLabelText(
                  'Super App',
                  style: AppText.labelLarge.copyWith(color: AppColors.white),
                ),
              ],
            ),
          ),
          if (onSkip != null)
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSkip,
                child: AppLabelText(
                  'Lewati',
                  style: AppText.labelMedium.copyWith(
                    color: AppColors.lightGray,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kotak ilustrasi 412×420 (63:1688 dkk.): di tengah layar, posisi elemen
/// sama dengan Figma, selalu dengan glow dan cincin progres halaman itu.
class _IllustrationFrame extends StatelessWidget {
  const _IllustrationFrame({required this.ring, required this.children});

  // Ukuran dan posisi tetap dari frame Figma (bukan variabel Figma).
  static const double width = 412;
  static const double height = 420;

  final AppIllustrations ring;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRect(
        child: OverflowBox(
          maxWidth: width,
          minWidth: width,
          child: Stack(
            children: [
              const Positioned(
                left: 36,
                top: 40,
                child: AppIllustration(AppIllustrations.introGlow),
              ),
              Positioned(left: 53, top: 57, child: AppIllustration(ring)),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Bayangan kartu melayang di ilustrasi (drop shadow 0/16/20, hitam 55%).
final List<BoxShadow> _floatShadow = [
  BoxShadow(
    color: AppColors.primary.withValues(alpha: 0.55),
    offset: const Offset(0, 16),
    blurRadius: 20,
  ),
];

/// Item komponen yang di Figma diberi latar kartu dan bayangan (instance
/// Notification Item dan Transaction Item di 00b/00c).
class _FloatingCard extends StatelessWidget {
  const _FloatingCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        // Figma mengikat garis ke Dark Gray tapi nilainya hitam (F-60).
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(AppRadius.item),
        boxShadow: _floatShadow,
      ),
      child: child,
    );
  }
}

/// Komponen yang sudah berupa kartu, cukup diberi bayangan.
class _Floating extends StatelessWidget {
  const _Floating({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.item),
        boxShadow: _floatShadow,
      ),
      child: child,
    );
  }
}

/// Chip ikon 52×52 (63:1741 dkk.).
class _IconChip extends StatelessWidget {
  const _IconChip(this.icon, {this.active = false});

  static const double size = 52;

  final AppIcons icon;

  /// Garis dan ikon oranye (Tugas di 00a).
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.item),
        border: Border.all(
          color: active ? AppColors.brandingOrange : AppColors.darkGray,
        ),
      ),
      child: AppIcon(
        icon,
        color: active ? AppColors.brandingOrange : AppColors.lightGray,
      ),
    );
  }
}

/// 00a (63:1688): logo besar dikelilingi delapan ikon modul.
class _ModulesIllustration extends StatelessWidget {
  const _ModulesIllustration();

  @override
  Widget build(BuildContext context) {
    return const _IllustrationFrame(
      ring: AppIllustrations.introRing1,
      children: [
        Positioned(
          left: 158,
          top: 162,
          child: AppLogoMark(size: AppLogoMarkSize.hero),
        ),
        Positioned(
          left: 180,
          top: 34,
          child: _IconChip(AppIcons.task, active: true),
        ),
        Positioned(left: 286, top: 78, child: _IconChip(AppIcons.calendar)),
        Positioned(left: 330, top: 184, child: _IconChip(AppIcons.wallet)),
        Positioned(left: 286, top: 290, child: _IconChip(AppIcons.timer)),
        Positioned(left: 180, top: 334, child: _IconChip(AppIcons.note)),
        Positioned(left: 74, top: 290, child: _IconChip(AppIcons.book)),
        Positioned(left: 30, top: 184, child: _IconChip(AppIcons.flame)),
        Positioned(left: 74, top: 78, child: _IconChip(AppIcons.learn)),
      ],
    );
  }
}

/// 00b (63:1796): notifikasi kelas, kelas yang sedang berlangsung, tugas.
class _StudyIllustration extends StatelessWidget {
  const _StudyIllustration();

  // Lebar kartu dari Figma.
  static const double _narrow = 324;
  static const double _wide = 364;

  @override
  Widget build(BuildContext context) {
    return const _IllustrationFrame(
      ring: AppIllustrations.introRing2,
      children: [
        Positioned(
          left: 44,
          top: 49,
          width: _narrow,
          child: _FloatingCard(
            child: AppNotificationItem(
              icon: AppIcons.calendar,
              iconColor: AppColors.white,
              title: 'Kelas 25 menit lagi',
              body: 'Pemrograman Mobile · Ruang 301',
              time: '07.35',
              showDivider: false,
            ),
          ),
        ),
        Positioned(
          left: 24,
          top: 159,
          width: _wide,
          child: AppClassItem(
            start: '08.00',
            end: '09.40',
            course: 'Pemrograman Mobile',
            meta: 'Ruang 301 · Bu Rina',
            state: AppClassItemState.now,
          ),
        ),
        Positioned(
          left: 44,
          top: 273,
          width: _narrow,
          child: _Floating(
            child: AppTaskItem(
              title: 'Laporan praktikum modul 5',
              meta: 'Pemrograman Mobile · 23.59',
              done: false,
              badge: AppBadge(label: 'Hari ini', type: AppBadgeType.warning),
            ),
          ),
        ),
      ],
    );
  }
}

/// 00c (63:1906): transaksi, budget, tagihan.
class _MoneyIllustration extends StatelessWidget {
  const _MoneyIllustration();

  // Lebar kartu dari Figma.
  static const double _narrow = 324;
  static const double _wide = 364;

  @override
  Widget build(BuildContext context) {
    return const _IllustrationFrame(
      ring: AppIllustrations.introRing3,
      children: [
        Positioned(
          left: 24,
          top: 77,
          width: _wide,
          child: _FloatingCard(
            child: AppTransactionItem(
              title: 'Sarapan',
              meta: 'Tunai · Makan · 07.10',
              amount: '−Rp15.000',
              type: AppTransactionType.expense,
              showDivider: false,
            ),
          ),
        ),
        Positioned(
          left: 44,
          top: 155,
          width: _narrow,
          child: _Floating(
            child: AppBudgetItem(
              title: 'Makan',
              amount: 'Rp480rb / Rp600rb',
              caption: 'Sisa Rp120rb · 80%',
              value: 80,
              status: AppBudgetStatus.warning,
            ),
          ),
        ),
        Positioned(
          left: 24,
          top: 261,
          width: _wide,
          child: _Floating(
            child: AppBillItem(
              day: '10',
              month: 'Nov',
              title: 'Kos',
              meta: 'Bulanan · Bank',
              amount: 'Rp800.000',
              status: AppBillStatus.upcoming,
              badgeLabel: '4 hari lagi',
            ),
          ),
        ),
      ],
    );
  }
}

/// 00d (63:2014): sidik jari di tengah, chip kunci dan sinkron.
class _SecureIllustration extends StatelessWidget {
  const _SecureIllustration();

  // Ukuran dan posisi tetap dari frame Figma (bukan variabel Figma).
  static const double _circle = 128;
  static const double _statusDot = 8;
  static const double _ringBorder = 1.5;

  @override
  Widget build(BuildContext context) {
    return _IllustrationFrame(
      ring: AppIllustrations.introRing,
      children: [
        Positioned(
          left: 142,
          top: 130,
          child: Container(
            width: _circle,
            height: _circle,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.brandingOrange,
                width: _ringBorder,
              ),
              boxShadow: _floatShadow,
            ),
            child: const AppIllustration(AppIllustrations.introFingerprint),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 282,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s16,
                vertical: AppSpace.s8,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColors.darkGray),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpace.s8,
                children: [
                  Container(
                    width: _statusDot,
                    height: _statusDot,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  AppLabelText(
                    'Tersinkron · HP & desktop',
                    style: AppText.labelSmall.copyWith(
                      color: AppColors.lightGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Positioned(left: 50, top: 109, child: _IconChip(AppIcons.lock)),
        const Positioned(
          left: 310,
          top: 109,
          child: _IconChip(AppIcons.refresh),
        ),
      ],
    );
  }
}
