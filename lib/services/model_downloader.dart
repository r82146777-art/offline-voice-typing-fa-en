import 'package:flutter/foundation.dart';

enum DownloadStatus { idle, checking, extracting, ready, error }

/// دیگر دانلود مدل لازم نیست — از موتور تشخیص سیستم استفاده می‌شود.
class ModelDownloader extends ChangeNotifier {
  DownloadStatus status = DownloadStatus.ready;
  double progress = 1.0;
  String? errorMessage;
  String? currentLanguage;

  Future<bool> isModelReady(String lang) async => true;

  Future<String?> getModelPath(String lang) async => null;

  Future<void> ensureModel(String lang) async {
    status = DownloadStatus.ready;
    progress = 1.0;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> retryCurrent() async {
    await ensureModel(currentLanguage ?? 'fa');
  }
}
