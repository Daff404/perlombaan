import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? error;
  try {
    await Firebase.initializeApp();
  } catch (_) {
    error = 'Firebase belum dikonfigurasi. Hubungkan proyek Firebase untuk menggunakan SHION.';
  }
  runApp(ProviderScope(child: ShionApp(configurationError: error)));
}
