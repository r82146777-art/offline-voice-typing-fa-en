import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final stt = context.watch<SttService>();
    final tts = context.read<TtsService>();
    final colorScheme = Theme.of(context).colorScheme;

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
        onSelectionChanged: (Set<SttLanguage> newSelection) {
          final lang = newSelection.first;
          stt.setLanguage(lang);
          tts.setLanguage(lang == SttLanguage.persian ? 'fa-IR' : 'en-US');
          tts.speak(
            lang == SttLanguage.persian
                ? 'زبان فارسی انتخاب شد'
                : 'English language selected',
          );
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.comfortable,
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ),
    );
  }
}
