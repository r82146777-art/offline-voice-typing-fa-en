import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  TtsService() {
    _init();
  }

  Future<void> _init() async {
    try {
      await _tts.setLanguage('fa-IR');
      await _tts.setSpeechRate(0.42);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> speak(String text, {String? languageCode}) async {
    if (!_ready || text.trim().isEmpty) return;
    try {
      if (languageCode != null) {
        await _tts.setLanguage(languageCode);
      }
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> setLanguage(String code) async {
    try {
      await _tts.setLanguage(code);
    } catch (_) {}
  }
}
