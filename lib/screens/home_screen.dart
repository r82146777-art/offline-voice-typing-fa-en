import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../widgets/big_mic_button.dart';
import '../widgets/language_switcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SttService>().initialize();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stt = context.watch<SttService>();
    final tts = context.read<TtsService>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // همگام‌سازی متن نهایی با کنترلر
    if (stt.finalText.isNotEmpty && _textController.text != stt.finalText) {
      _textController.text = stt.finalText;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text('تایپ صوتی آفلاین'),
        ),
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
              // انتخاب زبان
              const LanguageSwitcher(),
              const SizedBox(height: 16),

              // ناحیه متن (بزرگ و خوانا)
              Expanded(
                child: Semantics(
                  label: 'متن تایپ‌شده',
                  textField: true,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: theme.textTheme.titleLarge?.copyWith(
                        height: 1.6,
                        fontSize: 20,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: stt.language == SttLanguage.persian
                            ? 'متن اینجا ظاهر می‌شود...\nبرای شروع دکمه میکروفون را فشار دهید'
                            : 'Text will appear here...\nPress the microphone button to start',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.45),
                        ),
                      ),
                      onChanged: (value) {
                        // کاربر می‌تواند متن را دستی ویرایش کند
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // وضعیت فعلی
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  key: ValueKey(stt.state),
                  _statusText(stt),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),

              // دکمه بزرگ میکروفون
              BigMicButton(
                isListening: stt.isListening,
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
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 28),

              // راهنمای کوتاه
              Semantics(
                label: 'راهنما',
                child: Text(
                  stt.language == SttLanguage.persian
                      ? 'دکمه را فشار دهید و صحبت کنید. دوباره فشار دهید تا متن درج شود.'
                      : 'Press the button and speak. Press again to insert the text.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  String _statusText(SttService stt) {
    switch (stt.state) {
      case SttState.idle:
        return stt.language == SttLanguage.persian ? 'آماده' : 'Ready';
      case SttState.initializing:
        return stt.language == SttLanguage.persian
            ? 'در حال آماده‌سازی مدل...'
            : 'Loading model...';
      case SttState.listening:
        return stt.language == SttLanguage.persian
            ? 'در حال گوش دادن...'
            : 'Listening...';
      case SttState.processing:
        return stt.language == SttLanguage.persian
            ? 'در حال پردازش...'
            : 'Processing...';
      case SttState.error:
        return stt.errorMessage ?? 'خطا';
    }
  }
}
