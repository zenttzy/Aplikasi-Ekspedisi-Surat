import 'package:flutter/material.dart';

import 'features/splash/splash_page.dart';

/// Root widget aplikasi: tema & routing awal.
class EkspedisiSuratApp extends StatelessWidget {
  final bool isConfigured;

  const EkspedisiSuratApp({super.key, required this.isConfigured});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buku Ekspedisi Digital',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      home: SplashPage(isConfigured: isConfigured),
    );
  }
}
