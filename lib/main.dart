import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/local_store.dart';
import 'core/system_log.dart';
import 'ui/forest.dart';
import 'features/scanner_page.dart';
import 'features/places_page.dart';
import 'features/points_page.dart';
import 'features/deposit_page.dart';
import 'features/carbon_page.dart';
import 'ui/page_loading.dart';
import 'ui/shion_navigation.dart';
import 'ui/page_skin.dart';

part 'features/welcome_page.dart';
part 'features/dashboard_page.dart';
part 'features/education_page.dart';
part 'features/profile_page.dart';
part 'features/history_page.dart';
part 'features/articles.dart';
part 'app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    SystemLog.add('flutter', details.exceptionAsString());
  };
  ErrorWidget.builder = (_) => const Center(
    child: Text('Halaman belum dapat ditampilkan. Silakan buka kembali.'),
  );
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    SystemLog.add('unhandled', error);
    return true;
  };
  SystemLog.add('boot', 'SHION ready');
  runApp(const ShionApp());
}

class ShionApp extends StatelessWidget {
  const ShionApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SHION',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Manrope',
      colorScheme: const ColorScheme.dark(
        primary: sage,
        secondary: sage,
        surface: forest,
        onSurface: ink,
        onPrimary: forest,
      ),
      scaffoldBackgroundColor: forest,
      textTheme: ThemeData.dark().textTheme.apply(
        fontFamily: 'Manrope',
        bodyColor: ink,
        displayColor: ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: .055),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        labelStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0x33d7e8cc)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0x33d7e8cc)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: sage,
        contentTextStyle: TextStyle(color: forest),
      ),
    ),
    home: AnimatedBrandSplash(child: const ShionHome()),
  );
}
