import 'package:flutter_tts/flutter_tts.dart';

/// Uses the Android TTS engine and switches locale for Persian/English chunks.
/// Voice quality and offline availability depend on the speech voices installed on the device.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
    _initialized = true;
  }

  Future<void> speak(String text, {String? languageCode}) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await _init();
    final chunks = _splitByScript(clean);
    for (final chunk in chunks) {
      final isPersian = RegExp(r'[\u0600-\u06FF]').hasMatch(chunk);
      final locale = languageCode ?? (isPersian ? 'fa-IR' : 'en-US');
      try {
        await _tts.setLanguage(locale);
      } catch (_) {
        await _tts.setLanguage(isPersian ? 'fa' : 'en-US');
      }
      await _tts.speak(chunk);
    }
  }

  List<String> _splitByScript(String text) {
    final words = text.split(RegExp(r'(\s+)'));
    final result = <String>[];
    var buffer = StringBuffer();
    bool? currentPersian;
    for (final word in words) {
      if (word.isEmpty) continue;
      final hasPersian = RegExp(r'[\u0600-\u06FF]').hasMatch(word);
      final hasLatin = RegExp(r'[A-Za-z]').hasMatch(word);
      final script = hasPersian ? true : (hasLatin ? false : currentPersian);
      if (currentPersian != null && script != null && script != currentPersian && buffer.isNotEmpty) {
        result.add(buffer.toString());
        buffer = StringBuffer();
      }
      buffer.write(word);
      if (script != null) currentPersian = script;
    }
    if (buffer.isNotEmpty) result.add(buffer.toString());
    return result;
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> setLanguage(String code) async {
    await _init();
    await _tts.setLanguage(code);
  }
}
