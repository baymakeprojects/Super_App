import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/sync/sync_controller.dart';
import 'package:super_app/core/sync/sync_status.dart';
import 'package:super_app/core/ui/ui.dart';

/// Banner E5 (offline, Figma 68:2132) dan G8 (sinkron gagal, 137:4901).
/// Tidak menggambar apa pun kalau sinkron baik-baik saja.
///
/// [spacing] = jarak ke elemen sebelumnya, hanya dipakai saat banner tampil.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key, this.spacing = 0});

  final double spacing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = ref.watch(syncBannerProvider);
    if (kind == null) return const SizedBox.shrink();
    final pending = ref.watch(pendingChangesProvider).value ?? 0;

    void retry() =>
        unawaited(ref.read(syncControllerProvider.notifier).syncNow());

    final banner = switch (kind) {
      SyncBannerKind.offline => AppBanner(
        type: AppBannerType.warning,
        title: 'Kamu sedang offline',
        body: offlineBannerBody(pending),
        actionLabel: 'Coba lagi',
        onAction: retry,
      ),
      SyncBannerKind.failed => AppBanner(
        type: AppBannerType.danger,
        title: 'Sinkron gagal',
        body: failedBannerBody(pending),
        actionLabel: 'Coba lagi',
        onAction: retry,
      ),
    };
    return Padding(
      padding: EdgeInsets.only(top: spacing),
      child: banner,
    );
  }
}
