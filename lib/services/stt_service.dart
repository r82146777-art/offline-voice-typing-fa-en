import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

enum SttLanguage { persian, english }

enum SttState { idle, initializing, listening, processing, error }

class SttService extends ChangeNotifier {
  SttState _state = SttState.idle;
  SttLanguage _language = SttLanguage.persian;
  String _partialText = '';
  String _finalText = '';
  String? _errorMessage;
  bool _modelReady = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;

  SttState get state => _state;
  SttLanguage get language => _language;
  String get partialText => _partialText;
  String get finalText => _finalText;
  String? get errorMessage => _errorMessage;
  bool get isListening => _state == SttState.listening;
  bool get modelReady => _modelReady;

  String get langCode => _language == SttLanguage.persian ? 'fa' : 'en';

  String get _localeId =>
      _language == SttLanguage.persian ? 'fa_IR' : 'en_US';

  void setLanguage(SttLanguage lang) {
    if (_language != lang) {
      _language = lang;
      notifyListeners();
    }
  }

  void setModelReady(bool ready) {
    _modelReady = ready;
    notifyListeners();
  }

  Future<void> ensureEngineReady() async {
    if (_initialized && _modelReady) return;

    _state = SttState.initializing;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _speech.initialize(
        onError: (e) {
          _errorMessage = e.errorMsg;
          _state = SttState.error;
          notifyListeners();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (_state == SttState.listening) {
              _state = SttState.idle;
              notifyListeners();
            }
          }
        },
      );

      _initialized = ok;
      _modelReady = ok;
      _state = ok ? SttState.idle : SttState.error;
      if (!ok) {
        _errorMessage = 'موتور تشخیص گفتار در دسترس نیست';
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _state = SttState.error;
      _modelReady = false;
      notifyListeners();
    }
  }

  Future<void> startListening() async {
    if (_state == SttState.listening) return;

    try {
      if (!_initialized) {
        await ensureEngineReady();
      }
      if (!_initialized) {
        throw Exception(_errorMessage ?? 'موتور آماده نیست');
      }

      _partialText = '';
      _errorMessage = null;
      _state = SttState.listening;
      notifyListeners();

      await _speech.listen(
        onResult: _onResult,
        localeId: _localeId,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e) {
      _errorMessage = e.toString();
      _state = SttState.error;
      notifyListeners();
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      final text = result.recognizedWords.trim();
      if (text.isNotEmpty) {
        if (_finalText.isEmpty) {
          _finalText = text;
        } else {
          _finalText = '$_finalText $text';
        }
      }
      _partialText = '';
    } else {
      _partialText = result.recognizedWords;
    }
    notifyListeners();
  }

  Future<void> stopListening() async {
    if (_state != SttState.listening) return;

    try {
      _state = SttState.processing;
      notifyListeners();
      await _speech.stop();

      if (_partialText.trim().isNotEmpty) {
        final t = _partialText.trim();
        if (_finalText.isEmpty) {
          _finalText = t;
        } else {
          _finalText = '$_finalText $t';
        }
        _partialText = '';
      }

      _state = SttState.idle;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _state = SttState.error;
      notifyListeners();
    }
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
