import 'package:flutter/material.dart';
import '../features/dashboard/home.dart';

class ShionApp extends StatelessWidget {
  const ShionApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SHION', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffa9c8a1), brightness: Brightness.dark, surface: const Color(0xff102d25)),
      scaffoldBackgroundColor: const Color(0xff071b16),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      cardTheme: const CardThemeData(color: Color(0xff102d25)),
    ),
    home: const HomeScreen(),
  );
}
