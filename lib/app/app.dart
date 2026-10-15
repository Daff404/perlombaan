import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../features/authentication/auth_screen.dart';
import '../features/dashboard/home.dart';

class ShionApp extends StatelessWidget {
  const ShionApp({super.key, this.configurationError});
  final String? configurationError;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SHION', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffa9c8a1), brightness: Brightness.dark, surface: const Color(0xff102d25)),
      scaffoldBackgroundColor: const Color(0xff071b16),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      cardTheme: const CardTheme(color: Color(0xff102d25)),
    ),
    home: configurationError != null
      ? Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(28), child: Text(configurationError!))))
      : StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges(), builder: (context, state) {
          if (state.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          return state.data == null ? const AuthScreen() : const HomeScreen();
        }),
  );
}
