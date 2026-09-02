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

  static const _models = {
    'fa': {
      'url': 'https://alphacephei.com/vosk/models/vosk-model-small-fa-0.42.zip',
      'folder': 'vosk-model-small-fa-0.42',
    },
    'en': {
      'url': 'https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip',
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
    final modelPath = Directory('$base/$folder');
    final mdlFile = File('$base/$folder/am/final.mdl');
    return await modelPath.exists() && await mdlFile.exists();
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
      notifyListeners();
      return;
    }

    status = DownloadStatus.downloading;
    currentLanguage = lang;
    progress = 0.0;
    errorMessage = null;
    notifyListeners();

    try {
      final base = await modelsDir;
      final zipPath = '$base/$lang.zip';
      final url = _models[lang]!['url']!;

      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('دانلود ناموفق: ${response.statusCode}');
      }

      final total = response.contentLength ?? 0;
      final file = File(zipPath);
      final sink = file.openWrite();
      int received = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          progress = received / total;
          notifyListeners();
        }
      }
      await sink.close();

      status = DownloadStatus.extracting;
      notifyListeners();

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = '$base/${file.name}';
        if (file.isFile) {
          final outFile = File(filename);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filename).create(recursive: true);
        }
      }

      await file.delete();

      status = DownloadStatus.ready;
      progress = 1.0;
      notifyListeners();
    } catch (e, st) {
      debugPrint('Model download error: $e\n$st');
      status = DownloadStatus.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> ensureBothModels() async {
    await ensureModel('fa');
    if (status == DownloadStatus.error) return;
    await ensureModel('en');
  }
}
