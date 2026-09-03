import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _openImeSettings() async {
    try {
      const intent = AndroidIntent(
        action: 'android.settings.INPUT_METHOD_SETTINGS',
      );
      await intent.launch();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('راهنمای استفاده'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _Section(
            title: 'شروع کار در اپ',
            body:
                'مدل‌های فارسی و انگلیسی داخل اپ هستند. مجوز میکروفون را بدهید، دکمه میکروفون را بزنید، صحبت کنید و دوباره بزنید تا متن ثبت شود.',
          ),
          const _Section(
            title: 'فعال‌سازی به‌عنوان کیبورد سیستم',
            body:
                '۱. دکمه زیر کردن کیبورد در پایین همین صفحه را بزنید.\n'
                '۲. در لیست، «تایپ صوتی آفلاین» را روشن کنید.\n'
                '۳. هنگام تایپ در هر اپ، از آیکون کیبورد نوار اعلان، این کیبورد را انتخاب کنید.\n'
                '۴. روی میکروفون کیبورد بزنید و صحبت کنید — متن در همان فیلد درج می‌شود.',
          ),
          FilledButton.icon(
            onPressed: _openImeSettings,
            icon: const Icon(Icons.keyboard),
            label: const Text('باز کردن تنظیمات کیبورد'),
          ),
          const SizedBox(height: 20),
          const _Section(
            title: 'تغییر زبان',
            body:
                'در اپ از منو یا نوار زبان استفاده کنید. روی کیبورد سیستم دکمه FA/EN را بزنید.',
          ),
          const _Section(
            title: 'دسترسی‌پذیری',
            body:
                'دکمه‌ها برچسب TalkBack دارند. دکمه میکروفون بزرگ است. کیبورد سیستم هم برچسب‌های دسترس‌پذیر دارد.',
          ),
          const _Section(
            title: 'نکته',
            body:
                'تشخیص داخل اپ با مدل آفلاین Vosk است. روی کیبورد سیستم از موتور تشخیص گفتار سیستم اندروید استفاده می‌شود (برای فارسی/انگلیسی بسته به گوشی).',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}
