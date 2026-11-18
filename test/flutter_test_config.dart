import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_fonts.dart';

/// Dijalankan otomatis oleh `flutter test` sebelum setiap file tes.
/// Memuat font asli supaya golden test tidak memakai font kotak (Ahem).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadAppFonts();
  await testMain();
}
