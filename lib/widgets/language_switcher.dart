import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/model_downloader.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final stt = context.watch<SttService>();
    final tts = context.read<TtsService>();
    final downloader = context.read<ModelDownloader>();

    return Semantics(
      label: 'انتخاب زبان',
      child: SegmentedButton<SttLanguage>(
        segments: const [
          ButtonSegment(
            value: SttLanguage.persian,
            label: Text('فارسی'),
            icon: Icon(Icons.language),
          ),
          ButtonSegment(
            value: SttLanguage.english,
            label: Text('English'),
            icon: Icon(Icons.language),
          ),
        ],
        selected: {stt.language},
        onSelectionChanged: (Set<SttLanguage> newSelection) async {
          final lang = newSelection.first;
          stt.setLanguage(lang);
          final code = lang == SttLanguage.persian ? 'fa-IR' : 'en-US';
          await tts.setLanguage(code);
          await tts.speak(
            lang == SttLanguage.persian
                ? 'زبان فارسی انتخاب شد'
                : 'English language selected',
          );

          // اطمینان از وجود مدل زبان جدید
          final langCode = lang == SttLanguage.persian ? 'fa' : 'en';
          await downloader.ensureModel(langCode);
          if (downloader.status == DownloadStatus.ready) {
            stt.setModelReady(true);
          }
        },
      ),
    );
  }
}
