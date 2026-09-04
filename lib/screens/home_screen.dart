import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';

import '../services/stt_service.dart';
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
  bool _bootstrapping = false;
  bool _inviteShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowInviteDialog();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _maybeShowInviteDialog() async {
    if (_inviteShown || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final hide = prefs.getBool('hide_hamdel_invite') ?? false;
    if (hide || !mounted) return;
    _inviteShown = true;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('دعوت به کانال آکادمی همدل'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'به جمع گروه تکنولوژی همدل بپیوندید.\n\n'
                    'آموزش‌ها و اخبار تکنولوژی در کانال آکادمی همدل.',
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('دیگه نشونم نده'),
                    value: _dontShowInviteAgain,
                    onChanged: (v) =>
                        setDialogState(() => _dontShowInviteAgain = v ?? false),
                  ),
                ],
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
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('انتخاب زبان',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              title: const Text('فارسی (آفلاین)'),
              trailing: stt.language == SttLanguage.persian
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () => Navigator.pop(ctx, SttLanguage.persian),
            ),
            ListTile(
              title: const Text('English (Offline)'),
              trailing: stt.language == SttLanguage.english
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () => Navigator.pop(ctx, SttLanguage.english),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (selected != null && selected != stt.language) {
      stt.setLanguage(selected);
    }
  }

  Future<void> _openImeSettings() async {
    try {
      const intent =
          AndroidIntent(action: 'android.settings.INPUT_METHOD_SETTINGS');
      await intent.launch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    }
  }

  Future<void> _pickIme() async {
    await context.read<SttService>().showImePicker();
  }

  Future<void> _onMicPressed() async {
    final stt = context.read<SttService>();
    try {
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
      }
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('مجوز میکروفون لازم است'),
              action: SnackBarAction(
                label: 'تنظیمات',
                onPressed: openAppSettings,
              ),
            ),
          );
        }
        return;
      }

      if (stt.isListening) {
        await stt.stopListening();
        return;
      }

      if (mounted) setState(() => _bootstrapping = true);
      await stt.ensureEngineReady();
      if (mounted) setState(() => _bootstrapping = false);

      if (stt.state == SttState.error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(stt.errorMessage ?? 'خطا در موتور آفلاین'),
            ),
          );
        }
        return;
      }
      await stt.startListening();
    } catch (e) {
      if (mounted) {
        setState(() => _bootstrapping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    }
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_textController.text != displayText) {
          _textController.value = TextEditingValue(
            text: displayText,
            selection: TextSelection.collapsed(offset: displayText.length),
          );
        }
      });
    }

    final preparing =
        _bootstrapping || stt.state == SttState.initializing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تایپ صوتی آفلاین'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'پاک کردن',
            onPressed: () {
              stt.clearText();
              _textController.clear();
            },
            icon: const Icon(Icons.delete_outline),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'language':
                  await _showLanguagePicker();
                case 'ime':
                  await _openImeSettings();
                case 'picker':
                  await _pickIme();
                case 'help':
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpScreen()),
                    );
                  }
                case 'about':
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'language', child: Text('زبان')),
              PopupMenuItem(value: 'ime', child: Text('فعال‌سازی کیبورد')),
              PopupMenuItem(value: 'picker', child: Text('انتخاب کیبورد')),
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
              InkWell(
                onTap: _showLanguagePicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          stt.language == SttLanguage.persian
                              ? 'زبان: فارسی (آفلاین)'
                              : 'Language: English (Offline)',
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (preparing) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                const Text('در حال آماده‌سازی موتور آفلاین... لطفاً صبر کنید'),
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
                    stt.errorMessage ?? 'خطا',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        colorScheme.surfaceContainerHighest.withOpacity(0.45),
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
                    style: theme.textTheme.titleLarge
                        ?.copyWith(height: 1.55, fontSize: 19),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText:
                          'متن آفلاین اینجا ظاهر می‌شود...\nمیکروفون را بزنید و صحبت کنید',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                preparing
                    ? 'در حال آماده‌سازی...'
                    : stt.isListening
                        ? 'در حال گوش دادن (آفلاین)...'
                        : (stt.modelReady
                            ? 'آماده — کاملاً آفلاین'
                            : 'میکروفون را بزنید'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              BigMicButton(
                isListening: stt.isListening,
                enabled: !preparing || stt.isListening,
                onPressed: _onMicPressed,
              ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _openImeSettings,
                icon: const Icon(Icons.keyboard),
                label: const Text('1) فعال‌سازی کیبورد Offline Voice Typing'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickIme,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('2) انتخاب همین کیبورد آفلاین'),
              ),
              const SizedBox(height: 8),
              Text(
                'اگر هنوز آنلاین است، کیبورد گوگل فعال است. با دکمه 2 کیبورد آفلاین را انتخاب کنید.\nاینترنت لازم نیست.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
