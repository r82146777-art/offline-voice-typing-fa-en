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
    // مدل توسط ModelDownloader مدیریت می‌شود
  }

  Future<void> startListening() async {
    if (_state == SttState.listening) return;
    if (!_modelReady) {
      _errorMessage = 'مدل هنوز آماده نیست';
      _state = SttState.error;
      notifyListeners();
      return;
    }

    _partialText = '';
    _state = SttState.listening;
    _errorMessage = null;
    notifyListeners();

    // TODO: اتصال واقعی به Vosk + record
    // فعلاً شبیه‌سازی برای تست UI و جریان کار
  }

  Future<void> stopListening() async {
    if (_state != SttState.listening) return;

    _state = SttState.processing;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    // متن نمونه تا زمانی که موتور واقعی وصل شود
    final sample = _language == SttLanguage.persian
        ? 'این یک متن آزمایشی است. بعد از اتصال مدل واقعی، صدای شما به متن تبدیل می‌شود.'
        : 'This is sample text. After connecting the real model, your speech will be converted.';

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
