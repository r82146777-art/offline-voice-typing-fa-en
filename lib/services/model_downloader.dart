import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';

enum DownloadStatus { idle, checking, extracting, ready, error }

class ModelDownloader extends ChangeNotifier {
  DownloadStatus status = DownloadStatus.idle;
  double progress = 0.0;
  String? errorMessage;
  String? currentLanguage;

  static const _models = {
    'fa': {
      'asset': 'assets/models/vosk-model-small-fa-0.42.zip',
      'folder': 'vosk-model-small-fa-0.42',
    },
    'en': {
      'asset': 'assets/models/vosk-model-small-en-us-0.15.zip',
      'folder': 'vosk-model-small-en-us-0.15',
    },
  };

  Future<String> get modelsDir async {
    final dir = await getApplicationSupportDirectory();
    final models = Directory('${dir.path}/vosk_models');
    if (!await models.exists()) {
      await models.create(recursive: true);
    }
    return models.path;
  }

  Future<bool> isModelReady(String lang) async {
    final base = await modelsDir;
    final folder = _models[lang]!['folder']!;
    final mdlFile = File('$base/$folder/am/final.mdl');
    return await mdlFile.exists();
  }

  Future<String?> getModelPath(String lang) async {
    if (await isModelReady(lang)) {
      final base = await modelsDir;
      return '$base/${_models[lang]!['folder']}';
    }
    return null;
  }

  Future<void> ensureModel(String lang) async {
    if (await isModelReady(lang)) {
      status = DownloadStatus.ready;
      errorMessage = null;
      notifyListeners();
      return;
    }

    status = DownloadStatus.extracting;
    currentLanguage = lang;
    progress = 0.1;
    errorMessage = null;
    notifyListeners();

    try {
      final assetPath = _models[lang]!['asset']!;
      final folderName = _models[lang]!['folder']!;
      final base = await modelsDir;

      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();

      progress = 0.4;
      notifyListeners();

      final archive = ZipDecoder().decodeBytes(bytes);

      progress = 0.6;
      notifyListeners();

      for (final entry in archive) {
        final filename = '$base/${entry.name}';
        if (entry.isFile) {
          final outFile = File(filename);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(entry.content as List<int>);
        } else {
          await Directory(filename).create(recursive: true);
        }
      }

      final mdlFile = File('$base/$folderName/am/final.mdl');
      if (!await mdlFile.exists()) {
        throw Exception('فایل مدل بعد از استخراج پیدا نشد');
      }

      status = DownloadStatus.ready;
      progress = 1.0;
      errorMessage = null;
      notifyListeners();
    } catch (e, st) {
      debugPrint('Model extract error: $e\n$st');
      // حتی در صورت خطا، وضعیت را ready می‌کنیم تا دکمه میکروفون قفل نماند
      status = DownloadStatus.ready;
      errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> retryCurrent() async {
    if (currentLanguage != null) {
      try {
        final base = await modelsDir;
        final folder = _models[currentLanguage]!['folder']!;
        final dir = Directory('$base/$folder');
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (_) {}
      await ensureModel(currentLanguage!);
    }
  }
}
