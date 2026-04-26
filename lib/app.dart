import 'package:flutter/material.dart';
import 'shared/widgets/app_bottom_nav.dart';

class SpendoApp extends StatelessWidget {
  const SpendoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spendo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}