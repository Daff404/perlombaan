import 'package:flutter/foundation.dart';

class SystemLog {
  static final entries = ValueNotifier<List<String>>([]);
  static void add(String scope, Object message) {
    final safe = message
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
    final line = '${DateTime.now().toIso8601String()} [$scope] $safe';
    entries.value = [line, ...entries.value].take(200).toList();
    debugPrint(line);
  }

  static String failure(String scope, Object error) {
    add(scope, error);
    return 'Layanan belum tersedia. Silakan coba lagi.';
  }
}
