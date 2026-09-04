import 'package:flutter/foundation.dart';

enum DownloadStatus { idle, checking, extracting, ready, error }

/// Models are unpacked natively from Android assets. This class is a UI stub.
class ModelDownloader extends ChangeNotifier {
  DownloadStatus status = DownloadStatus.ready;
  double progress = 1.0;
  String? errorMessage;
  String? currentLanguage;

  Future<void> ensureModel(String lang) async {
    currentLanguage = lang;
    status = DownloadStatus.ready;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> retryCurrent() async {
    if (currentLanguage != null) {
      await ensureModel(currentLanguage!);
    }
  }
}
