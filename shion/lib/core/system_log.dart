// ==== [ IDRUS - FRONTEND ] ==== //
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class SystemLog {
  static final daftarEntri = ValueNotifier<List<String>>([]);
  static void add(String scope, Object message) {
    final aman = message
        .toString()
        .replaceAll(RegExp(r'AQ\.[A-Za-z0-9_-]+'), '[REDACTED]')
        .replaceAll(RegExp(r'AIza[A-Za-z0-9_-]+'), '[REDACTED]')
        .replaceAll(
          RegExp(
            r'(x-goog-api-key|api_key|key)\s*[:=]\s*[^\s,}]+',
            caseSensitive: false,
          ),
          'key=[REDACTED]',
        );
    final baris = '${DateTime.now().toIso8601String()} [$scope] $aman';
    daftarEntri.value = [baris, ...daftarEntri.value].take(200).toList();
    debugPrint(baris);
  }

  static String failure(String scope, Object error) {
    add(scope, error);
    if (error is ApiException) return error.pesan;
    return 'Layanan belum tersedia. Silakan coba lagi.';
  }
}
