import 'package:material_ui/material_ui.dart';

/// Akar aplikasi Super App.
///
/// Masih kosong di W1-01. Tema dari token Figma menyusul di W1-03,
/// dan go_router dengan shell 5 tab di W1-09.
class SuperApp extends StatelessWidget {
  const SuperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super App',
      debugShowCheckedModeBanner: false,
      // Sementara: palet gelap bawaan supaya layar kosong tidak putih.
      // Diganti ThemeData dari lib/core/theme di W1-03.
      theme: ThemeData(brightness: Brightness.dark),
      home: const Scaffold(),
    );
  }
}
