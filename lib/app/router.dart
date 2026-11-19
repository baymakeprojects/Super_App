import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/placeholder_screen.dart';
import 'package:super_app/app/routes.dart';
import 'package:super_app/core/ui/catalog_page.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/features/tugas/presentation/task_detail_screen.dart';
import 'package:super_app/features/tugas/presentation/task_form_screen.dart';
import 'package:super_app/features/tugas/presentation/tugas_screen.dart';

/// Router app. Rutenya persis seperti tabel di `docs/navigasi.md`.
///
/// - Lima tab Bottom Nav memakai `StatefulShellRoute.indexedStack`, jadi
///   posisi gulir dan filter tiap tab tetap saat berpindah tab.
/// - Layar tanpa Bottom Nav (form, detail, pengaturan) dibuka di navigator
///   akar, menutupi shell; Back kembali ke tab asalnya.
/// - Pengalihan saat app dibuka (cek sesi → Intro/Kunci/Beranda) menyusul
///   di W1-10 bersama login. Untuk sekarang app mulai di Beranda.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = buildAppRouter();
  ref.onDispose(router.dispose);
  return router;
});

GoRouter buildAppRouter({String initialLocation = AppRoutes.beranda}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  /// Rute layar penuh (tanpa Bottom Nav) di dalam cabang tab.
  GoRoute fullScreen(
    String path,
    String title, {
    List<RouteBase> routes = const [],
    Widget? screen,
  }) {
    return GoRoute(
      path: path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => screen ?? PlaceholderScreen(title: title),
      routes: routes,
    );
  }

  /// Rute akar tanpa Bottom Nav.
  GoRoute topLevel(
    String path,
    String title, {
    List<RouteBase> routes = const [],
  }) {
    return GoRoute(
      path: path,
      builder: (context, state) => PlaceholderScreen(title: title),
      routes: routes,
    );
  }

  /// Satu tab Bottom Nav.
  StatefulShellBranch tab(
    String path,
    String title, {
    List<RouteBase> routes = const [],
    bool showDebugRoutes = false,
    Widget? screen,
  }) {
    return StatefulShellBranch(
      routes: [
        GoRoute(
          path: path,
          builder: (context, state) =>
              screen ??
              PlaceholderScreen(
                title: title,
                inShell: true,
                showDebugRoutes: showDebugRoutes,
              ),
          routes: routes,
        ),
      ],
    );
  }

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      topLevel(AppRoutes.intro, 'Intro'),
      topLevel(
        AppRoutes.kunci,
        'Kunci sidik jari',
        routes: [topLevel('pin', 'Masukkan PIN')],
      ),
      topLevel(AppRoutes.setupJadwal, 'Jadwal semester'),
      topLevel(AppRoutes.setupDompet, 'Dompet & saldo awal'),
      topLevel(AppRoutes.setupKeamanan, 'Keamanan'),
      topLevel(
        AppRoutes.pengaturan,
        'Pengaturan',
        routes: [topLevel('pin', 'Atur PIN cadangan')],
      ),
      if (kDebugMode)
        GoRoute(
          path: AppRoutes.katalog,
          builder: (context, state) => const CatalogPage(),
        ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _TabShell(navigationShell: navigationShell),
        branches: [
          tab(AppRoutes.beranda, 'Beranda'),
          tab(
            AppRoutes.tugas,
            'Tugas',
            screen: const TugasScreen(),
            routes: [
              // 'baru' dan 'cari' sebelum ':id' supaya tidak dianggap id.
              fullScreen('baru', 'Tugas baru', screen: const TaskFormScreen()),
              fullScreen('cari', 'Pencarian'),
              GoRoute(
                path: ':id',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) =>
                    TaskDetailScreen(taskId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) =>
                        TaskFormScreen(taskId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          tab(
            AppRoutes.kuliah,
            'Kuliah',
            routes: [
              fullScreen('jadwal-baru', 'Jadwal baru'),
              fullScreen(
                ':id',
                'Detail mata kuliah',
                routes: [fullScreen('edit', 'Ubah jadwal')],
              ),
            ],
          ),
          tab(
            AppRoutes.keuangan,
            'Keuangan',
            routes: [
              fullScreen('transaksi-baru', 'Transaksi baru'),
              fullScreen('transaksi/:id', 'Ubah transaksi'),
            ],
          ),
          tab(AppRoutes.lainnya, 'Lainnya', showDebugRoutes: true),
        ],
      ),
    ],
  );
}

/// Kerangka lima tab: isi tab aktif + Bottom Nav.
///
/// Aturan Back (`navigasi.md`): di tab selain Beranda, Back pindah ke tab
/// Beranda; di Beranda, Back keluar dari app.
class _TabShell extends StatelessWidget {
  const _TabShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const int _berandaIndex = 0;

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;

    return PopScope(
      canPop: index == _berandaIndex,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(_berandaIndex);
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: AppBottomNav(
          currentIndex: index,
          // Mengetuk tab yang sedang aktif kembali ke halaman awal tab itu.
          onTap: (i) =>
              navigationShell.goBranch(i, initialLocation: i == index),
        ),
      ),
    );
  }
}
