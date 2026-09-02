import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// سرویس تشخیص گفتار آفلاین
/// در نسخه فعلی اسکلت آماده است. بعد از اضافه کردن مدل‌های Vosk
/// و اتصال پلاگین vosk_flutter کامل می‌شود.
enum SttLanguage { persian, english }

enum SttState { idle, initializing, listening, processing, error }

class SttService extends ChangeNotifier {
  SttState _state = SttState.idle;
  SttLanguage _language = SttLanguage.persian;
  String _partialText = '';
  String _finalText = '';
  String? _errorMessage;

  SttState get state => _state;
  SttLanguage get language => _language;
  String get partialText => _partialText;
  String get finalText => _finalText;
  String? get errorMessage => _errorMessage;
  bool get isListening => _state == SttState.listening;

  void setLanguage(SttLanguage lang) {
    if (_language != lang) {
      _language = lang;
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    _state = SttState.initializing;
    notifyListeners();

    try {
      // TODO: بارگذاری مدل Vosk مربوط به زبان انتخاب‌شده
      // مثال:
      // final modelPath = await _getModelPath(_language);
      // await VoskFlutterPlugin.instance().createModel(modelPath);
      await Future.delayed(const Duration(milliseconds: 800)); // شبیه‌سازی
      _state = SttState.idle;
      _errorMessage = null;
    } catch (e) {
      _state = SttState.error;
      _errorMessage = 'خطا در بارگذاری مدل: $e';
    }
    notifyListeners();
  }

  Future<void> startListening() async {
    if (_state == SttState.listening) return;

    _partialText = '';
    _finalText = '';
    _state = SttState.listening;
    notifyListeners();

    // TODO: شروع ضبط و ارسال به recognizer
    // در نسخه واقعی از record + vosk استفاده می‌شود
  }

  Future<void> stopListening() async {
    if (_state != SttState.listening) return;

    _state = SttState.processing;
    notifyListeners();

    // شبیه‌سازی نتیجه (در نسخه واقعی از Vosk می‌آید)
    await Future.delayed(const Duration(milliseconds: 600));
    _finalText = _language == SttLanguage.persian
        ? 'این یک متن آزمایشی فارسی است'
        : 'This is a sample English text';
    _state = SttState.idle;
    notifyListeners();
  }

  void clearText() {
    _partialText = '';
    _finalText = '';
    notifyListeners();
  }

  void appendFinalText(String text) {
    if (_finalText.isEmpty) {
      _finalText = text;
    } else {
      _finalText = '$_finalText $text';
    }
    notifyListeners();
  }
}
