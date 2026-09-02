import 'package:flutter/foundation.dart';

/// سرویس تشخیص گفتار آفلاین
///
/// وضعیت فعلی: اسکلت کامل + شبیه‌سازی
/// برای فعال‌سازی واقعی:
/// 1. مدل‌های Vosk را در assets/models/fa و assets/models/en قرار دهید
/// 2. پلاگین vosk_flutter را به درستی پیکربندی کنید
/// 3. کد TODOها را با پیاده‌سازی واقعی جایگزین کنید
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

  void setLanguage(SttLanguage lang) {
    if (_language != lang) {
      _language = lang;
      // در نسخه واقعی مدل جدید بارگذاری می‌شود
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    _state = SttState.initializing;
    notifyListeners();

    try {
      // TODO: بارگذاری واقعی مدل
      // final modelDir = await _resolveModelPath(_language);
      // ...
      await Future.delayed(const Duration(milliseconds: 900));
      _modelReady = true;
      _state = SttState.idle;
      _errorMessage = null;
    } catch (e, st) {
      debugPrint('STT init error: $e\n$st');
      _state = SttState.error;
      _errorMessage = 'خطا در آماده‌سازی مدل. مدل‌ها را دانلود کرده‌اید؟';
      _modelReady = false;
    }
    notifyListeners();
  }

  Future<void> startListening() async {
    if (_state == SttState.listening) return;
    if (!_modelReady) {
      await initialize();
      if (!_modelReady) return;
    }

    _partialText = '';
    _state = SttState.listening;
    notifyListeners();

    // TODO: شروع ضبط واقعی با پکیج record و ارسال به Vosk
  }

  Future<void> stopListening() async {
    if (_state != SttState.listening) return;

    _state = SttState.processing;
    notifyListeners();

    // شبیه‌سازی نتیجه (جایگزین با نتیجه واقعی Vosk شود)
    await Future.delayed(const Duration(milliseconds: 700));

    final sample = _language == SttLanguage.persian
        ? 'سلام، این یک متن آزمایشی فارسی است. لطفاً مدل واقعی را فعال کنید.'
        : 'Hello, this is a sample English text. Please enable the real model.';

    if (_finalText.isEmpty) {
      _finalText = sample;
    } else {
      _finalText = '$_finalText $sample';
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
