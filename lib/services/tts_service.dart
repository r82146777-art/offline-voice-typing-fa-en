import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  TtsService() {
    _init();
  }

  Future<void> _init() async {
    await _tts.setLanguage('fa-IR');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> speak(String text, {String? languageCode}) async {
    if (languageCode != null) {
      await _tts.setLanguage(languageCode);
    }
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> setLanguage(String code) async {
    await _tts.setLanguage(code);
  }
}
