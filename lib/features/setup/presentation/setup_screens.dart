import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/routes.dart';
import 'package:super_app/core/db/enums.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/core/utils/money_format.dart';
import 'package:super_app/core/utils/rupiah_input_formatter.dart';
import 'package:super_app/features/auth/application/session_controller.dart';
import 'package:super_app/features/keuangan/application/keuangan_providers.dart';
import 'package:super_app/features/keuangan/data/finance_repository_provider.dart';
import 'package:super_app/features/keuangan/presentation/wallet_sheets.dart';
import 'package:super_app/features/kuliah/application/academic_term.dart';
import 'package:super_app/features/kuliah/application/kuliah_providers.dart';
import 'package:super_app/features/kuliah/application/semester_choices.dart';
import 'package:super_app/features/kuliah/data/course_repository.dart';
import 'package:super_app/features/kuliah/data/semester_repository_provider.dart';
import 'package:super_app/features/kuliah/presentation/semester_sheet.dart';
import 'package:super_app/features/setup/presentation/setup_scaffold.dart';

/// `/setup/jadwal`: 01a Jadwal semester (Figma 66:1786).
class SetupScheduleScreen extends ConsumerWidget {
  const SetupScheduleScreen({super.key});

  Future<void> _pickSemester(BuildContext context, WidgetRef ref) async {
    final semesters = ref.read(semesterRepositoryProvider);
    final choices = await loadSemesterChoices(
      semesters,
      today: ref.read(clockProvider)(),
    );
    if (!context.mounted) return;
    final choice = await showSemesterSheet(context: context, choices: choices);
    if (choice != null) await activateSemesterChoice(semesters, choice);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semester = ref.watch(activeSemesterProvider).value;
    final schedule = ref.watch(scheduleProvider).value ?? const [];

    return SetupScaffold(
      step: 1,
      title: 'Isi jadwal semester ini',
      body:
          'Dipakai untuk pengingat kelas dan kalender. Bisa diubah kapan saja '
          'di Kuliah.',
      actionLabel: 'Lanjut →',
      onAction: () => context.push(AppRoutes.setupDompet),
      children: [
        AppSelect(
          label: 'Semester',
          value: semester == null ? null : semesterTitle(semester),
          // Belum ada semester: belum ada frame (F-52).
          placeholder: 'Pilih semester',
          onTap: () => _pickSemester(context, ref),
        ),
        if (schedule.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            // Jarak 4 juga di antara baris (Figma 66:1814).
            spacing: AppSpace.s4,
            children: [
              AppLabelText(
                'Mata kuliah · ${schedule.length}',
                style: AppText.labelMedium.copyWith(color: AppColors.lightGray),
              ),
              for (final entry in schedule)
                AppListRow(
                  icon: AppIcons.learn,
                  title: entry.course.name,
                  subtitle: _scheduleCaption(entry),
                  horizontalPadding: 0,
                  onTap: () =>
                      context.push(AppRoutes.kuliahEdit(entry.course.id)),
                ),
            ],
          ),
        AppButton(
          label: '+ Tambah mata kuliah',
          style: AppButtonStyle.ghost,
          onPressed: () => context.push(AppRoutes.kuliahJadwalBaru),
        ),
      ],
    );
  }

  /// "Jumat · 08.00–09.40 · Ruang 301".
  static String _scheduleCaption(ScheduleEntry entry) {
    final session = entry.session;
    return [
      CourseRepository.weekdayName(session.weekday),
      '${CourseRepository.displayTime(session.startsAt)}–'
          '${CourseRepository.displayTime(session.endsAt)}',
      ?entry.room,
    ].join(' · ');
  }
}

/// Dompet bawaan setup awal (data model: Tunai, Bank, E-wallet).
const List<(String, WalletKind)> _defaultWallets = [
  ('Tunai', WalletKind.cash),
  ('Bank', WalletKind.bank),
  ('E-wallet', WalletKind.ewallet),
];

/// `/setup/dompet`: 01b Dompet & saldo awal (Figma 66:1852).
///
/// Belum ada dompet: tiga kolom saldo awal Tunai, Bank, E-wallet; dompetnya
/// dibuat saat "Lanjut". Dompet yang sudah ada (misalnya dari "+ Dompet
/// lain") tampil dengan saldonya dan tidak bisa diubah di sini (F-52).
class SetupWalletScreen extends ConsumerStatefulWidget {
  const SetupWalletScreen({super.key});

  @override
  ConsumerState<SetupWalletScreen> createState() => _SetupWalletScreenState();
}

class _SetupWalletScreenState extends ConsumerState<SetupWalletScreen> {
  final List<TextEditingController> _amounts = [
    for (final _ in _defaultWallets) TextEditingController(),
  ];

  /// Kolom baca-saja untuk dompet yang sudah ada, per id dompet.
  final Map<String, TextEditingController> _existing = {};
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [..._amounts, ..._existing.values]) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _existingField(String id, int balance) {
    final controller = _existing.putIfAbsent(id, TextEditingController.new);
    controller.text = AppMoneyFormat.rupiah(balance);
    return controller;
  }

  /// Buat dompet Tunai, Bank, E-wallet dengan saldo awal dari kolom.
  Future<void> _createDefaults() async {
    setState(() => _saving = true);
    final finance = ref.read(financeRepositoryProvider);
    for (final (i, (name, kind)) in _defaultWallets.indexed) {
      await finance.addWallet(
        name: name,
        kind: kind,
        openingBalance: RupiahInputFormatter.parse(_amounts[i].text),
      );
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _next({required bool createDefaults}) async {
    if (createDefaults) await _createDefaults();
    if (mounted) await context.push(AppRoutes.setupKeamanan);
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletsProvider).value;
    final existing = wallets ?? const [];
    // Kolom bawaan hanya kalau belum ada dompet sama sekali.
    final drafts = wallets != null && wallets.isEmpty;
    final total =
        existing.fold<int>(0, (sum, w) => sum + w.balance) +
        (drafts
            ? _amounts.fold<int>(
                0,
                (sum, c) => sum + RupiahInputFormatter.parse(c.text),
              )
            : 0);

    return SetupScaffold(
      step: 2,
      title: 'Dompet & saldo awal',
      body: 'Isi saldo sekarang supaya catatan keuangan langsung akurat.',
      actionLabel: 'Lanjut →',
      onAction: wallets == null || _saving
          ? null
          : () => _next(createDefaults: drafts),
      children: [
        for (final wallet in existing)
          AppInput(
            label: wallet.wallet.name,
            controller: _existingField(wallet.wallet.id, wallet.balance),
            enabled: false,
          ),
        if (drafts)
          for (final (i, (name, _)) in _defaultWallets.indexed)
            AppInput(
              label: name,
              placeholder: 'Rp0',
              controller: _amounts[i],
              keyboardType: TextInputType.number,
              inputFormatters: const [RupiahInputFormatter()],
              onChanged: (_) => setState(() {}),
            ),
        AppButton(
          label: '+ Dompet lain',
          style: AppButtonStyle.ghost,
          onPressed: () async {
            // Dompet bawaan dibuat dulu supaya urutannya tetap
            // Tunai, Bank, E-wallet, lalu dompet lain.
            if (drafts) await _createDefaults();
            if (context.mounted) await showNewWalletSheet(context);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppLabelText(
              'Total saldo',
              style: AppText.labelMedium.copyWith(color: AppColors.lightGray),
            ),
            Text(
              AppMoneyFormat.rupiah(total),
              style: AppText.bodyLarge.copyWith(color: AppColors.white),
            ),
          ],
        ),
      ],
    );
  }
}

/// `/setup/keamanan`: 01c Keamanan (Figma 66:1898), tanpa grup Pengingat
/// (Tahap 2, design-notes §7).
class SetupSecurityScreen extends ConsumerWidget {
  const SetupSecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockOn = ref.watch(biometricLockProvider).value ?? true;
    final hasPin = ref.watch(hasPinProvider).value ?? false;

    return SetupScaffold(
      step: 3,
      title: 'Keamanan & pengingat',
      body:
          'Kunci app dengan sidik jari, lalu pilih pengingat yang mau kamu '
          'terima.',
      actionLabel: 'Selesai, ke Beranda →',
      onAction: () => finishSetupAndGoHome(context, ref),
      children: [
        Column(
          children: [
            AppListRow(
              icon: AppIcons.fingerprint,
              title: 'Kunci sidik jari',
              subtitle: 'Diminta setiap app dibuka',
              horizontalPadding: 0,
              trailing: AppListRowSwitch(
                value: lockOn,
                onChanged: (on) => unawaited(
                  ref.read(biometricLockProvider.notifier).set(on: on),
                ),
              ),
            ),
            AppListRow(
              icon: AppIcons.lock,
              title: 'PIN cadangan',
              // Teks "sudah diatur" belum ada di Figma (F-52).
              subtitle: hasPin
                  ? 'Sudah diatur · dipakai kalau sidik jari gagal'
                  : 'Belum diatur · dipakai kalau sidik jari gagal',
              horizontalPadding: 0,
              onTap: () => context.push(AppRoutes.pengaturanPin),
            ),
          ],
        ),
      ],
    );
  }
}
