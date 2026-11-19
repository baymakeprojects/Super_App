import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/placeholder_screen.dart';
import 'package:super_app/app/routes.dart';
import 'package:super_app/core/ui/catalog_page.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/features/auth/application/session_controller.dart';
import 'package:super_app/features/auth/presentation/code_screen.dart';
import 'package:super_app/features/auth/presentation/email_screen.dart';
import 'package:super_app/features/auth/presentation/intro_screen.dart';
import 'package:super_app/features/auth/presentation/lock_screen.dart';
import 'package:super_app/features/auth/presentation/pin_screen.dart';
import 'package:super_app/features/beranda/presentation/beranda_screen.dart';
import 'package:super_app/features/keuangan/presentation/keuangan_screen.dart';
import 'package:super_app/features/keuangan/presentation/transaction_form_screen.dart';
import 'package:super_app/features/kuliah/presentation/course_detail_screen.dart';
import 'package:super_app/features/kuliah/presentation/course_form_screen.dart';
import 'package:super_app/features/kuliah/presentation/kuliah_screen.dart';
import 'package:super_app/features/tugas/presentation/task_detail_screen.dart';
import 'package:super_app/features/tugas/presentation/task_form_screen.dart';
import 'package:super_app/features/tugas/presentation/tugas_screen.dart';

/// Router app. Rutenya persis seperti tabel di `docs/navigasi.md`.
///
/// - Lima tab Bottom Nav memakai `StatefulShellRoute.indexedStack`, jadi
///   posisi gulir dan filter tiap tab tetap saat berpindah tab.
/// - Layar tanpa Bottom Nav (form, detail, pengaturan) dibuka di navigator
///   akar, menutupi shell; Back kembali ke tab asalnya.
/// - Pengalihan mengikuti sesi login ([sessionRedirect]): belum login ke
///   Intro, sudah login ke Kunci sidik jari, sesi berakhir ke G1.
final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ValueNotifier(ref.read(sessionControllerProvider));
  ref
    ..listen(sessionControllerProvider, (_, next) => session.value = next)
    ..onDispose(session.dispose);
  final router = buildAppRouter(session: session);
  ref.onDispose(router.dispose);
  return router;
});

/// Rute tujuan untuk [location] menurut [session], atau `null` kalau boleh
/// tetap di sana (navigasi.md › Alur saat app dibuka).
String? sessionRedirect(SessionState session, String location) {
  bool at(String route) => location == route || location.startsWith('$route/');
  final onLogin = at(AppRoutes.masuk);

  switch (session.status) {
    case SessionStatus.signedOut:
      return at(AppRoutes.intro) || onLogin ? null : AppRoutes.intro;
    case SessionStatus.expired:
      // G1 tampil di /kunci; "Masuk lagi" membuka /masuk.
      return location == AppRoutes.kunci || onLogin ? null : AppRoutes.kunci;
    case SessionStatus.locked:
      // "Lupa PIN?" boleh masuk ulang dengan email.
      return at(AppRoutes.kunci) || onLogin ? null : AppRoutes.kunci;
    case SessionStatus.unlocked:
      return at(AppRoutes.intro) || onLogin || at(AppRoutes.kunci)
          ? AppRoutes.beranda
          : null;
  }
}

/// [session] `null` = tanpa pengalihan (dipakai tes rute).
GoRouter buildAppRouter({
  String initialLocation = AppRoutes.beranda,
  ValueListenable<SessionState>? session,
}) {
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
    refreshListenable: session,
    redirect: session == null
        ? null
        : (context, state) =>
              sessionRedirect(session.value, state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.intro,
        builder: (context, state) => const IntroScreen(),
      ),
      GoRoute(
        path: AppRoutes.masuk,
        builder: (context, state) => const EmailScreen(),
        routes: [
          GoRoute(
            path: 'kode',
            builder: (context, state) => const CodeScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.kunci,
        builder: (context, state) => const LockScreen(),
        routes: [
          GoRoute(path: 'pin', builder: (context, state) => const PinScreen()),
        ],
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
          tab(AppRoutes.beranda, 'Beranda', screen: const BerandaScreen()),
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
            screen: const KuliahScreen(),
            routes: [
              fullScreen(
                'jadwal-baru',
                'Jadwal baru',
                screen: const CourseFormScreen(),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) =>
                    CourseDetailScreen(courseId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) =>
                        CourseFormScreen(courseId: state.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          tab(
            AppRoutes.keuangan,
            'Keuangan',
            screen: const KeuanganScreen(),
            routes: [
              fullScreen(
                'transaksi-baru',
                'Transaksi baru',
                screen: const TransactionFormScreen(),
              ),
              GoRoute(
                path: 'transaksi/:id',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => TransactionFormScreen(
                  transactionId: state.pathParameters['id'],
                ),
              ),
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
