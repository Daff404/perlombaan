// ==== [ IDRUS - FRONTEND ] ==== //
// ==== [ MUIS - UI UX ] ==== //
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'core/api_store.dart';
import 'features/leaderboard_page.dart';
import 'features/notifications_page.dart';
import 'features/admin_page.dart';
import 'features/remote_education_page.dart';
import 'features/password_page.dart';
import 'features/points_qr_page.dart';
import 'features/community_page.dart';
import 'services/device_access.dart';
import 'core/system_log.dart';
import 'ui/forest.dart';
import 'features/scanner_page.dart';
import 'features/chatbot_page.dart';
import 'features/places_page.dart';
import 'features/points_page.dart';
import 'features/deposit_page.dart';
import 'features/carbon_page.dart';
import 'ui/page_loading.dart';
import 'ui/shion_navigation.dart';
import 'ui/page_skin.dart';

part 'features/auth_flow.dart';
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
  const ShionApp({super.key, this.store});
  final ApiStore? store;
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
        secondary: terracotta,
        surface: surface,
        onSurface: ink,
        onPrimary: forestDeep,
      ),
      scaffoldBackgroundColor: surface,
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        backgroundColor: const Color(0xff009d20), foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      )),
      textTheme: ThemeData.dark().textTheme.apply(
        fontFamily: 'Manrope',
        bodyColor: ink,
        displayColor: ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xff153b2c),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        labelStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xff4b6b55)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xff4b6b55)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: forestDeep,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    ),
    home: AnimatedBrandSplash(child: ShionHome(store: store)),
  );
}
