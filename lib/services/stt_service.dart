import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum SttLanguage { persian, english }

enum SttState { idle, initializing, listening, processing, error }

class SttService extends ChangeNotifier {
  static const _method = MethodChannel('offline_voice_typing/vosk');
  static const _events = EventChannel('offline_voice_typing/vosk_events');

  SttState _state = SttState.idle;
  SttLanguage _language = SttLanguage.persian;
  String _partialText = '';
  String _finalText = '';
  String? _errorMessage;
  bool _modelReady = false;
  bool _initInProgress = false;
  StreamSubscription? _eventSub;

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
      _modelReady = false;
      notifyListeners();
    }
  }

  Future<void> _ensureEventListen() async {
    if (_eventSub != null) return;
    _eventSub = _events.receiveBroadcastStream().listen((event) {
      if (event is! Map) return;
      final type = event['type']?.toString() ?? '';
      final text = event['text']?.toString() ?? '';
      switch (type) {
        case 'partial':
          _partialText = text;
          notifyListeners();
        case 'final':
          if (text.trim().isNotEmpty) {
            _finalText =
                _finalText.isEmpty ? text.trim() : '$_finalText ${text.trim()}';
          }
          _partialText = '';
          notifyListeners();
        case 'error':
          _errorMessage = text;
          _state = SttState.error;
          notifyListeners();
        case 'status':
          if (text == 'listening') {
            _state = SttState.listening;
          } else if (text == 'idle') {
            if (_state == SttState.listening || _state == SttState.processing) {
              _state = SttState.idle;
            }
          }
          notifyListeners();
      }
    }, onError: (e) {
      debugPrint('Vosk events error: $e');
    });
  }

  Future<void> ensureEngineReady() async {
    if (_modelReady && !_initInProgress) return;
    if (_initInProgress) return;

    _initInProgress = true;
    _state = SttState.initializing;
    _errorMessage = null;
    notifyListeners();

    try {
      await _ensureEventListen();
      final ok = await _method.invokeMethod<bool>('prepare', {'lang': langCode});
      if (ok != true) {
        throw Exception('آماده‌سازی موتور آفلاین ناموفق بود');
      }
      _modelReady = true;
      _state = SttState.idle;
      notifyListeners();
    } catch (e, st) {
      debugPrint('STT init error: $e\n$st');
      _errorMessage = e.toString();
      _state = SttState.error;
      _modelReady = false;
      notifyListeners();
    } finally {
      _initInProgress = false;
    }
  }

  Future<void> startListening() async {
    if (_state == SttState.listening) return;
    try {
      await _ensureEventListen();
      _partialText = '';
      _errorMessage = null;
      await _method.invokeMethod('start', {'lang': langCode});
    } catch (e) {
      _errorMessage = e.toString();
      _state = SttState.error;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    if (_state != SttState.listening) return;
    try {
      _state = SttState.processing;
      notifyListeners();
      await _method.invokeMethod('stop');
      if (_partialText.trim().isNotEmpty) {
        final t = _partialText.trim();
        _finalText = _finalText.isEmpty ? t : '$_finalText $t';
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

  Future<void> showImePicker() async {
    try {
      await _method.invokeMethod('showImePicker');
    } catch (e) {
      debugPrint('IME picker: $e');
    }
  }

  void clearText() {
    _partialText = '';
    _finalText = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    try {
      _method.invokeMethod('stop');
    } catch (_) {}
    super.dispose();
  }
}
