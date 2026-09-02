import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/model_downloader.dart';
import '../widgets/big_mic_button.dart';
import '../widgets/language_switcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final status = await Permission.microphone.request();
    _permissionGranted = status.isGranted;

    final downloader = context.read<ModelDownloader>();
    final stt = context.read<SttService>();

    // دانلود مدل زبان فعلی
    final lang = stt.langCode;
    await downloader.ensureModel(lang);

    if (downloader.status == DownloadStatus.ready) {
      stt.setModelReady(true);
    }

    setState(() {});
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stt = context.watch<SttService>();
    final downloader = context.watch<ModelDownloader>();
    final tts = context.read<TtsService>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // همگام‌سازی متن
    if (stt.finalText.isNotEmpty && _textController.text != stt.finalText) {
      _textController.text = stt.finalText;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }

    final isDownloading = downloader.status == DownloadStatus.downloading ||
        downloader.status == DownloadStatus.extracting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تایپ صوتی آفلاین'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'پاک کردن متن',
            onPressed: () {
              stt.clearText();
              _textController.clear();
              tts.speak('متن پاک شد');
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              const LanguageSwitcher(),
              const SizedBox(height: 12),

              // نوار پیشرفت دانلود مدل
              if (isDownloading) ...[
                LinearProgressIndicator(value: downloader.progress),
                const SizedBox(height: 8),
                Text(
                  downloader.status == DownloadStatus.extracting
                      ? 'در حال استخراج مدل...'
                      : 'در حال دانلود مدل (${(downloader.progress * 100).toStringAsFixed(0)}٪)',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
              ],

              if (downloader.status == DownloadStatus.error)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'خطا در دانلود مدل: ${downloader.errorMessage}',
                    style: TextStyle(color: colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),

              // ناحیه متن
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.25),
                    ),
                  ),
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: theme.textTheme.titleLarge?.copyWith(
                      height: 1.55,
                      fontSize: 19,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: stt.language == SttLanguage.persian
                          ? 'متن اینجا ظاهر می‌شود...\nدکمه میکروفون را فشار دهید'
                          : 'Text will appear here...\nPress the microphone button',
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                _statusText(stt, downloader),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 18),

              BigMicButton(
                isListening: stt.isListening,
                enabled: !isDownloading && stt.modelReady && _permissionGranted,
                onPressed: () async {
                  if (stt.isListening) {
                    await stt.stopListening();
                    await tts.speak(
                      stt.language == SttLanguage.persian
                          ? 'ضبط متوقف شد'
                          : 'Recording stopped',
                    );
                  } else {
                    await tts.speak(
                      stt.language == SttLanguage.persian
                          ? 'شروع ضبط'
                          : 'Start recording',
                    );
                    await stt.startListening();
                  }
                },
              ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 24),

              Text(
                stt.language == SttLanguage.persian
                    ? 'دکمه را فشار دهید و صحبت کنید. دوباره فشار دهید تا متن درج شود.'
                    : 'Press the button and speak. Press again to insert the text.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.65),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  String _statusText(SttService stt, ModelDownloader downloader) {
    if (downloader.status == DownloadStatus.downloading) {
      return 'در حال دانلود مدل...';
    }
    if (downloader.status == DownloadStatus.extracting) {
      return 'در حال آماده‌سازی مدل...';
    }
    if (downloader.status == DownloadStatus.error) {
      return 'خطا در مدل';
    }
    switch (stt.state) {
      case SttState.idle:
        return stt.modelReady ? (stt.language == SttLanguage.persian ? 'آماده' : 'Ready') : 'مدل آماده نیست';
      case SttState.initializing:
        return 'در حال آماده‌سازی...';
      case SttState.listening:
        return stt.language == SttLanguage.persian ? 'در حال گوش دادن...' : 'Listening...';
      case SttState.processing:
        return stt.language == SttLanguage.persian ? 'در حال پردازش...' : 'Processing...';
      case SttState.error:
        return stt.errorMessage ?? 'خطا';
    }
  }
}
