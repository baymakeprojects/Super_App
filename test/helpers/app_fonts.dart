import 'dart:convert';

import 'package:flutter/services.dart';

/// Memuat semua font yang didaftarkan di pubspec.yaml (lewat FontManifest),
/// jadi daftar font cukup ditulis di satu tempat.
Future<void> loadAppFonts() async {
  final manifestJson = await rootBundle.loadString('FontManifest.json');
  final manifest = jsonDecode(manifestJson) as List<dynamic>;

  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    // Font bawaan paket (misalnya MaterialIcons) tidak dipakai di golden.
    if (family.startsWith('packages/') || family == 'MaterialIcons') continue;

    final loader = FontLoader(family);
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}
