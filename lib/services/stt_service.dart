import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:vosk_flutter/vosk_flutter.dart';
import 'model_downloader.dart';

enum SttLanguage { persian, english }

enum SttState { idle, initializing, listening, processing, error }

/// تشخیص گفتار کاملاً آفلاین با Vosk
class SttService extends ChangeNotifier {
  SttState _state = SttState.idle;
  SttLanguage _language = SttLanguage.persian;
  String _partialText = '';
  String _finalText = '';
  String? _errorMessage;
  bool _modelReady = false;

  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;
  StreamSubscription? _partialSub;
  StreamSubscription? _resultSub;
  ModelDownloader? _downloader;

  SttState get state => _state;
  SttLanguage get language => _language;
  String get partialText => _partialText;
  String get finalText => _finalText;
  String? get errorMessage => _errorMessage;
  bool get isListening => _state == SttState.listening;
  bool get modelReady => _modelReady;
  String get langCode => _language == SttLanguage.persian ? 'fa' : 'en';

  void attachDownloader(ModelDownloader downloader) {
    _downloader = downloader;
  }

  void setLanguage(SttLanguage lang) {
    if (_language != lang) {
      _language = lang;
      _disposeEngine();
      _modelReady = false;
      notifyListeners();
    }
  }

  void setModelReady(bool ready) {
    _modelReady = ready;
    notifyListeners();
  }

  Future<void> ensureEngineReady() async {
    if (_speechService != null && _modelReady) return;

    _state = SttState.initializing;
    _errorMessage = null;
    notifyListeners();

    try {
      final downloader = _downloader;
      if (downloader == null) {
        throw Exception('ModelDownloader متصل نیست');
      }

      await downloader.ensureModel(langCode);
      if (downloader.status == DownloadStatus.error) {
        throw Exception(downloader.errorMessage ?? 'خطا در مدل');
      }

      final modelPath = await downloader.getModelPath(langCode);
      if (modelPath == null) {
        throw Exception('مسیر مدل پیدا نشد');
      }

      _model = await _vosk.createModel(modelPath);
      _recognizer = await _vosk.createRecognizer(
        model: _model!,
        sampleRate: 16000,
      );
      _speechService = await _vosk.initSpeechService(_recognizer!);

      await _partialSub?.cancel();
      await _resultSub?.cancel();

      _partialSub = _speechService!.onPartial().listen((jsonStr) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          final partial = (map['partial'] as String?) ?? '';
          if (partial.isNotEmpty) {
            _partialText = partial;
            notifyListeners();
          }
        } catch (_) {}
      });

      _resultSub = _speechService!.onResult().listen((jsonStr) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          final text = (map['text'] as String?)?.trim() ?? '';
          if (text.isNotEmpty) {
            _finalText = _finalText.isEmpty ? text : '$_finalText $text';
            _partialText = '';
            notifyListeners();
          }
        } catch (_) {}
      });

      _modelReady = true;
      _state = SttState.idle;
      notifyListeners();
    } catch (e, st) {
      debugPrint('STT init error: $e\n$st');
      _errorMessage = e.toString();
      _state = SttState.error;
      _modelReady = false;
      notifyListeners();
    }
  }

  Future<void> startListening() async {
    if (_state == SttState.listening) return;
    try {
      if (_speechService == null) {
        await ensureEngineReady();
      }
      if (_speechService == null) {
        throw Exception(_errorMessage ?? 'موتور آفلاین آماده نیست');
      }
      _partialText = '';
      _errorMessage = null;
      await _speechService!.start();
      _state = SttState.listening;
      notifyListeners();
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
      await _speechService?.stop();
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

  void clearText() {
    _partialText = '';
    _finalText = '';
    notifyListeners();
  }

  void setFinalText(String text) {
    _finalText = text;
    notifyListeners();
  }

  void _disposeEngine() {
    _partialSub?.cancel();
    _resultSub?.cancel();
    _partialSub = null;
    _resultSub = null;
    try {
      _speechService?.stop();
    } catch (_) {}
    _speechService = null;
    _recognizer = null;
    _model = null;
  }

  @override
  void dispose() {
    _disposeEngine();
    super.dispose();
  }
}
