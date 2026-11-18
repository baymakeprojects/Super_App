import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';

/// Akar aplikasi Super App.
///
/// go_router dengan shell 5 tab menyusul di W1-09.
class SuperApp extends StatelessWidget {
  const SuperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const Scaffold(),
    );
  }
}
