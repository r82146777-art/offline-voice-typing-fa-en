import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';

enum DownloadStatus { idle, checking, downloading, extracting, ready, error }

class ModelDownloader extends ChangeNotifier {
  DownloadStatus status = DownloadStatus.idle;
  double progress = 0.0;
  String? errorMessage;
  String? currentLanguage;

  // چند آدرس مختلف برای هر مدل (در صورت قطع بودن یکی، بعدی امتحان می‌شود)
  static const _models = {
    'fa': {
      'folder': 'vosk-model-small-fa-0.42',
      'urls': [
        'https://alphacephei.com/vosk/models/vosk-model-small-fa-0.42.zip',
        'https://github.com/alphacep/vosk-api/releases/download/0.3.42/vosk-model-small-fa-0.42.zip',
      ],
    },
    'en': {
      'folder': 'vosk-model-small-en-us-0.15',
      'urls': [
        'https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip',
        'https://github.com/alphacep/vosk-api/releases/download/0.3.42/vosk-model-small-en-us-0.15.zip',
      ],
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
    final folder = _models[lang]!['folder'] as String;
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

    status = DownloadStatus.downloading;
    currentLanguage = lang;
    progress = 0.0;
    errorMessage = null;
    notifyListeners();

    final urls = List<String>.from(_models[lang]!['urls'] as List);
    Exception? lastError;

    for (final url in urls) {
      try {
        await _downloadAndExtract(lang, url);
        status = DownloadStatus.ready;
        progress = 1.0;
        errorMessage = null;
        notifyListeners();
        return;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        debugPrint('Download failed from $url → $e');
      }
    }

    status = DownloadStatus.error;
    errorMessage =
        'نتوانست مدل را دانلود کند.\n\n' +
        'لطفاً اتصال اینترنت را چک کنید یا VPN روشن کنید و دوباره امتحان کنید.\n\n' +
        'جزئیات: ${lastError?.toString() ?? "خطای ناشناخته"}';
    notifyListeners();
  }

  Future<void> _downloadAndExtract(String lang, String url) async {
    final base = await modelsDir;
    final zipPath = '$base/$lang.zip';

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request).timeout(
            const Duration(seconds: 90),
          );

      if (response.statusCode != 200) {
        throw Exception('کد خطا: ${response.statusCode}');
      }

      final total = response.contentLength ?? 0;
      final file = File(zipPath);
      final sink = file.openWrite();
      int received = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          progress = (received / total).clamp(0.0, 0.95);
          notifyListeners();
        }
      }
      await sink.close();

      status = DownloadStatus.extracting;
      notifyListeners();

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

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

      try {
        await file.delete();
      } catch (_) {}
    } finally {
      client.close();
    }
  }

  Future<void> retryCurrent() async {
    if (currentLanguage != null) {
      await ensureModel(currentLanguage!);
    }
  }
}
