import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/routes.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/features/auth/application/session_controller.dart';
import 'package:super_app/features/auth/data/profile_repository.dart';

/// `/pengaturan`: 14 Pengaturan versi MVP (Figma 27:1092): kartu akun dan
/// grup Keamanan. Grup Data dan Notifikasi (Tahap 2) disembunyikan
/// (design-notes §7, navigasi.md).
class PengaturanScreen extends ConsumerWidget {
  const PengaturanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(profileNameProvider).value;
    final email = ref.watch(accountEmailProvider);
    final lockOn = ref.watch(biometricLockProvider).value ?? true;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppTopAppBar(
        title: 'Pengaturan',
        leadingIcon: AppIcons.arrowLeft,
        onLeadingPressed: context.pop,
        leadingSemanticLabel: 'Kembali',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s20,
          AppSpace.s8,
          AppSpace.s20,
          AppSpace.s24,
        ),
        children: [
          _AccountCard(
            name: name,
            email: email,
            onTap: () => showAccountSheet(context, name: name, email: email),
          ),
          const SizedBox(height: AppSpace.s20),
          _Group(
            label: 'Keamanan',
            rows: [
              AppListRow(
                icon: AppIcons.fingerprint,
                title: 'Kunci sidik jari',
                subtitle: 'Minta sidik jari saat app dibuka',
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
                showDivider: false,
                onTap: () => context.push(AppRoutes.pengaturanPin),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Nama akun di kartu dan P37: nama profil, kalau belum ada email (F-14).
String accountTitle(String? name, String? email) => name ?? email ?? 'Akun';

/// Kartu akun (27:1111): avatar 48, nama, keterangan, chevron.
class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.name,
    required this.email,
    required this.onTap,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _avatarSize = 48;
  static const double _avatarIconSize = 20;
  static const double _chevronSize = 20;
  static const double _textGap = 2;

  final String? name;
  final String? email;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final trimmed = name?.trim();
    final initial = trimmed == null || trimmed.isEmpty
        ? null
        : trimmed.characters.first.toUpperCase();
    final radius = BorderRadius.circular(AppRadius.card);

    return Material(
      color: AppColors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.darkGray),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s16),
          child: Row(
            spacing: AppSpace.s12,
            children: [
              Container(
                width: _avatarSize,
                height: _avatarSize,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.brandingOrange,
                  shape: BoxShape.circle,
                ),
                // Tanpa nama: ikon User, sama dengan avatar Beranda (F-45).
                child: initial == null
                    ? const AppIcon(
                        AppIcons.user,
                        size: _avatarIconSize,
                        color: AppColors.onAccent,
                      )
                    : AppLabelText(
                        initial,
                        style: AppText.labelLarge.copyWith(
                          color: AppColors.onAccent,
                        ),
                      ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: _textGap,
                  children: [
                    Text(
                      accountTitle(name, email),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.titleMedium.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    // Teks Figma "Masuk dengan Google · 2 perangkat" (F-55).
                    Text(
                      'Masuk dengan email',
                      style: AppText.bodySmall.copyWith(color: AppColors.gray),
                    ),
                  ],
                ),
              ),
              const AppIcon(
                AppIcons.chevronRight,
                color: AppColors.gray,
                size: _chevronSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grup pengaturan (27:1119): label kecil, lalu kartu berisi List Row.
class _Group extends StatelessWidget {
  const _Group({required this.label, required this.rows});

  final String label;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s8,
      children: [
        AppLabelText(
          label,
          style: AppText.labelSmall.copyWith(color: AppColors.gray),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.darkGray),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(children: rows),
          ),
        ),
      ],
    );
  }
}

/// P37 Akun (Figma 88:5795) versi MVP: daftar perangkat dan "Sinkron hanya
/// lewat Wi-Fi" disembunyikan (desktop dan pengaturan sinkron Tahap 2,
/// F-55). "Keluar dari akun" membuka P38.
Future<void> showAccountSheet(
  BuildContext context, {
  required String? name,
  required String? email,
}) async {
  final signOut = await showAppBottomSheet<bool>(
    context: context,
    builder: (sheetContext) => AppBottomSheet(
      title: 'Akun',
      subtitle: '${accountTitle(name, email)} · masuk dengan email',
      onClose: () => Navigator.of(sheetContext).pop(),
      body: Text(
        'Semua data tersimpan di cloud dan tersinkron otomatis antar '
        'perangkat.',
        style: AppText.bodySmall.copyWith(color: AppColors.gray),
      ),
      footer: [
        AppButton(
          label: 'Keluar dari akun',
          style: AppButtonStyle.danger,
          onPressed: () => Navigator.of(sheetContext).pop(true),
        ),
      ],
    ),
  );
  if (signOut == true && context.mounted) {
    await showSignOutSheet(context);
  }
}

/// P38 Keluar akun (Figma 88:5875).
Future<void> showSignOutSheet(BuildContext context) {
  return showAppBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) => AppBottomSheet(
        title: 'Keluar dari akun?',
        showClose: false,
        body: Text(
          'Data di HP ini akan dihapus. Tugas, jadwal, dan keuangan tetap '
          'aman di cloud dan muncul lagi saat kamu masuk.',
          style: AppText.bodyLarge.copyWith(color: AppColors.lightGray),
        ),
        footer: [
          AppButton(
            label: 'Batal',
            style: AppButtonStyle.ghost,
            onPressed: () => Navigator.of(sheetContext).pop(),
          ),
          AppButton(
            label: 'Keluar',
            style: AppButtonStyle.danger,
            onPressed: () async {
              // Dibaca sebelum sheet ditutup: ref sheet tidak berlaku lagi
              // setelah sheet hilang.
              final session = ref.read(sessionControllerProvider.notifier);
              Navigator.of(sheetContext).pop();
              await session.signOut();
            },
          ),
        ],
      ),
    ),
  );
}
