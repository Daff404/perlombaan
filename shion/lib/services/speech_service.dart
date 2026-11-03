// ==== [ IDRUS - FRONTEND ] ==== //
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Uses Android's installed Indonesian text-to-speech engine; no cloud audio
/// service or additional API key is required.
class SpeechService {
  static const _kanal = MethodChannel('id.shion.app/speech');

  Future<void> speak(String text) async {
    if (kIsWeb || text.trim().isEmpty) return;
    await _kanal.invokeMethod<void>('speak', {'text': text.trim()});
  }

  Future<void> stop() async {
    if (kIsWeb) return;
    await _kanal.invokeMethod<void>('stop');
  }
}
