import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';

import '../services/stt_service.dart';
import '../services/model_downloader.dart';
import '../widgets/big_mic_button.dart';
import 'help_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _dontShowInviteAgain = false;
  bool _bootstrapping = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _bootstrap();
      await _maybeShowInviteDialog();
    });
  }

  Future<void> _bootstrap() async {
    final stt = context.read<SttService>();
    await Permission.microphone.request();
    try {
      await stt.ensureEngineReady();
    } catch (e) {
      debugPrint('Bootstrap STT: $e');
    }
    if (mounted) setState(() => _bootstrapping = false);
  }

  Future<void> _maybeShowInviteDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final hide = prefs.getBool('hide_hamdel_invite') ?? false;
    if (hide || !mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('دعوت به کانال آکادمی همدل'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'به جمع گروه تکنولوژی همدل بپیوندید.\n\n'
                      'در کانال آکادمی همدل آخرین آموزش‌ها و اخبار تکنولوژی را دنبال کنید.',
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('دیگه نشونم نده'),
                      value: _dontShowInviteAgain,
                      onChanged: (v) {
                        setDialogState(() => _dontShowInviteAgain = v ?? false);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (_dontShowInviteAgain) {
                      await prefs.setBool('hide_hamdel_invite', true);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('لغو'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (_dontShowInviteAgain) {
                      await prefs.setBool('hide_hamdel_invite', true);
                    }
                    final uri = Uri.parse('https://t.me/Akademi_hamdel');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('عضو می‌شم'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showLanguagePicker() async {
    final stt = context.read<SttService>();
    final selected = await showModalBottomSheet<SttLanguage>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('انتخاب زبان', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('فارسی'),
                trailing: stt.language == SttLanguage.persian
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => Navigator.pop(ctx, SttLanguage.persian),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('English'),
                trailing: stt.language == SttLanguage.english
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => Navigator.pop(ctx, SttLanguage.english),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
    if (selected != null) stt.setLanguage(selected);
  }

  Future<void> _openImeSettings() async {
    try {
      const intent = AndroidIntent(action: 'android.settings.INPUT_METHOD_SETTINGS');
      await intent.launch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    }
  }

  Future<void> _onMicPressed() async {
    final stt = context.read<SttService>();
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('مجوز میکروفون لازم است'),
            action: SnackBarAction(label: 'تنظیمات', onPressed: openAppSettings),
          ),
        );
      }
      return;
    }

    if (stt.isListening) {
      await stt.stopListening();
    } else {
      await stt.startListening();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stt = context.watch<SttService>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final displayText = stt.finalText +
        (stt.partialText.isNotEmpty
            ? (stt.finalText.isEmpty ? stt.partialText : ' ${stt.partialText}')
            : '');

    if (_textController.text != displayText) {
      _textController.text = displayText;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }

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
            },
            icon: const Icon(Icons.delete_outline),
          ),
          PopupMenuButton<String>(
            tooltip: 'منو',
            onSelected: (value) async {
              switch (value) {
                case 'language':
                  await _showLanguagePicker();
                case 'ime':
                  await _openImeSettings();
                case 'help':
                  if (mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()));
                  }
                case 'about':
                  if (mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                  }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'language', child: Text('زبان')),
              PopupMenuItem(value: 'ime', child: Text('فعال‌سازی کیبورد سیستم')),
              PopupMenuItem(value: 'help', child: Text('راهنما')),
              PopupMenuItem(value: 'about', child: Text('درباره ما')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              Semantics(
                label: 'زبان فعلی: ${stt.language == SttLanguage.persian ? "فارسی" : "انگلیسی"}',
                child: InkWell(
                  onTap: _showLanguagePicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.language),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            stt.language == SttLanguage.persian ? 'زبان: فارسی' : 'Language: English',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_bootstrapping) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                const Text('در حال آماده‌سازی موتور تشخیص گفتار...'),
                const SizedBox(height: 12),
              ],
              if (stt.state == SttState.error && stt.errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    stt.errorMessage!,
                    style: TextStyle(color: colorScheme.onErrorContainer),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              Expanded(
                child: Semantics(
                  label: 'جعبه متن تشخیص گفتار',
                  textField: true,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.outline.withOpacity(0.25)),
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: theme.textTheme.titleLarge?.copyWith(height: 1.55, fontSize: 19),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: stt.language == SttLanguage.persian
                            ? 'متن اینجا ظاهر می‌شود...\nدکمه میکروفون را بزنید و صحبت کنید'
                            : 'Text appears here...\nPress mic and speak',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(
                  _statusText(stt),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              BigMicButton(
                isListening: stt.isListening,
                enabled: true,
                onPressed: _onMicPressed,
              ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openImeSettings,
                icon: const Icon(Icons.keyboard),
                label: const Text('فعال‌سازی به‌عنوان کیبورد سیستم'),
              ),
              const SizedBox(height: 12),
              Text(
                stt.language == SttLanguage.persian
                    ? 'میکروفون را بزنید، صحبت کنید، دوباره بزنید تا متن ثبت شود.'
                    : 'Tap mic, speak, tap again to stop.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _statusText(SttService stt) {
    if (_bootstrapping) return 'در حال آماده‌سازی...';
    switch (stt.state) {
      case SttState.idle:
        return stt.language == SttLanguage.persian ? 'آماده — صحبت کنید' : 'Ready — speak';
      case SttState.initializing:
        return 'در حال آماده‌سازی موتور...';
      case SttState.listening:
        return stt.language == SttLanguage.persian ? 'در حال گوش دادن...' : 'Listening...';
      case SttState.processing:
        return stt.language == SttLanguage.persian ? 'در حال پردازش...' : 'Processing...';
      case SttState.error:
        return 'خطا — دوباره تلاش کنید';
    }
  }
}
