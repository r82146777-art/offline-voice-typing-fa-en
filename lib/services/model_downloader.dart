import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';

enum DownloadStatus { idle, checking, extracting, ready, error }

/// مدل‌های Vosk داخل APK هستند و فقط یک‌بار استخراج می‌شوند.
class ModelDownloader extends ChangeNotifier {
  DownloadStatus status = DownloadStatus.idle;
  double progress = 0.0;
  String? errorMessage;
  String? currentLanguage;
  bool _busy = false;

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

  Future<String?> _findModelRoot(String base, String preferredFolder) async {
    final preferred = Directory('$base/$preferredFolder');
    if (await File('${preferred.path}/am/final.mdl').exists()) {
      return preferred.path;
    }
    // جستجوی بازگشتی اگر ساختار زیپ متفاوت بود
    try {
      await for (final entity in Directory(base).list(recursive: true)) {
        if (entity is File && entity.path.endsWith('/am/final.mdl')) {
          return entity.parent.parent.path;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool> isModelReady(String lang) async {
    final base = await modelsDir;
    final folder = _models[lang]!['folder']!;
    final root = await _findModelRoot(base, folder);
    return root != null;
  }

  Future<String?> getModelPath(String lang) async {
    final base = await modelsDir;
    final folder = _models[lang]!['folder']!;
    return _findModelRoot(base, folder);
  }

  Future<void> ensureModel(String lang) async {
    if (_busy) return;
    if (await isModelReady(lang)) {
      status = DownloadStatus.ready;
      errorMessage = null;
      notifyListeners();
      return;
    }

    _busy = true;
    status = DownloadStatus.extracting;
    currentLanguage = lang;
    progress = 0.05;
    errorMessage = null;
    notifyListeners();

    try {
      final assetPath = _models[lang]!['asset']!;
      final folderName = _models[lang]!['folder']!;
      final base = await modelsDir;

      // کپی به فایل موقت به‌جای نگه‌داشتن کل زیپ در RAM به‌صورت همزمان
      final tmpZip = File('$base/$folderName.zip');
      final data = await rootBundle.load(assetPath);
      progress = 0.25;
      notifyListeners();

      await tmpZip.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      progress = 0.4;
      notifyListeners();

      final bytes = await tmpZip.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes, verify: false);
      progress = 0.55;
      notifyListeners();

      var i = 0;
      final total = archive.length.clamp(1, 1000000);
      for (final entry in archive) {
        final name = entry.name.replaceAll('\\', '/');
        final outPath = '$base/$name';
        if (entry.isFile) {
          final outFile = File(outPath);
          await outFile.parent.create(recursive: true);
          final content = entry.content;
          if (content is List<int>) {
            await outFile.writeAsBytes(content, flush: false);
          }
        } else {
          await Directory(outPath).create(recursive: true);
        }
        i++;
        if (i % 20 == 0) {
          progress = 0.55 + (0.4 * i / total);
          notifyListeners();
          // اجازه تنفس به UI
          await Future<void>.delayed(Duration.zero);
        }
      }

      try {
        if (await tmpZip.exists()) await tmpZip.delete();
      } catch (_) {}

      final root = await _findModelRoot(base, folderName);
      if (root == null) {
        throw Exception('فایل مدل (am/final.mdl) بعد از استخراج پیدا نشد');
      }

      status = DownloadStatus.ready;
      progress = 1.0;
      errorMessage = null;
      notifyListeners();
    } catch (e, st) {
      debugPrint('Model extract error: $e\n$st');
      status = DownloadStatus.error;
      errorMessage = 'خطا در آماده‌سازی مدل آفلاین:\n$e';
      notifyListeners();
    } finally {
      _busy = false;
    }
  }

  Future<void> retryCurrent() async {
    if (currentLanguage == null) return;
    try {
      final base = await modelsDir;
      final folder = _models[currentLanguage]!['folder']!;
      final dir = Directory('$base/$folder');
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
    await ensureModel(currentLanguage!);
  }
}
