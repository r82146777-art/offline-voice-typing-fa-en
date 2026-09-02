import 'package:flutter/foundation.dart';

enum SttLanguage { persian, english }

enum SttState { idle, initializing, listening, processing, error }

class SttService extends ChangeNotifier {
  SttState _state = SttState.idle;
  SttLanguage _language = SttLanguage.persian;
  String _partialText = '';
  String _finalText = '';
  String? _errorMessage;
  bool _modelReady = false;

  SttState get state => _state;
  SttLanguage get language => _language;
  String get partialText => _partialText;
  String get finalText => _finalText;
  String? get errorMessage => _errorMessage;
  bool get isListening => _state == SttState.listening;
  bool get modelReady => _modelReady;

  String get langCode => _language == SttLanguage.persian ? 'fa' : 'en';

  void setLanguage(SttLanguage lang) {
    if (_language != lang) {
      _language = lang;
      notifyListeners();
    }
  }

  void setModelReady(bool ready) {
    _modelReady = ready;
    if (ready && _state == SttState.initializing) {
      _state = SttState.idle;
    }
    notifyListeners();
  }

  Future<void> initialize() async {
    _state = SttState.initializing;
    notifyListeners();
  }

  Future<void> startListening() async {
    if (_state == SttState.listening) return;

    // حتی اگر مدل کامل آماده نباشد، اجازه ضبط آزمایشی بده
    _partialText = '';
    _state = SttState.listening;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> stopListening() async {
    if (_state != SttState.listening) return;

    _state = SttState.processing;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final sample = _language == SttLanguage.persian
        ? 'این یک متن آزمایشی است. موتور واقعی تشخیص گفتار در نسخه‌های بعدی وصل می‌شود.'
        : 'This is sample text. Real speech recognition will be connected in future versions.';

    if (_finalText.isEmpty) {
      _finalText = sample;
    } else {
      _finalText = '$_finalText\n$sample';
    }

    _state = SttState.idle;
    notifyListeners();
  }

  void clearText() {
    _partialText = '';
    _finalText = '';
    notifyListeners();
  }

  void setFinalText(String text) {
    _finalText = text;
    notifyListeners();
  }
}
