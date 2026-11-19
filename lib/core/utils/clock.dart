import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Jam app. Di tes diganti dengan waktu tetap (misalnya Jumat 6 Nov 2026
/// 07.40 seperti di Figma) supaya "hari ini", "besok", dan "terlambat"
/// bisa diuji.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
