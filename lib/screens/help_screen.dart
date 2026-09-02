import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('راهنمای استفاده'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Section(
            title: 'شروع کار',
            body:
                'بعد از نصب، اپ کاملاً آفلاین کار می‌کند. مدل‌های فارسی و انگلیسی داخل خود برنامه هستند و نیازی به اینترنت ندارند.',
          ),
          _Section(
            title: 'چگونه تایپ صوتی کنیم؟',
            body:
                '۱. دکمه بزرگ میکروفون را یک‌بار بزنید.\n'
                '۲. صحبت کنید.\n'
                '۳. دوباره دکمه را بزنید تا متن در جعبه متن درج شود.\n'
                '۴. در صورت نیاز متن را ویرایش یا پاک کنید.',
          ),
          _Section(
            title: 'تغییر زبان',
            body:
                'از منوی بالا (سه نقطه) گزینه «زبان» را انتخاب کنید یا روی نوار زبان در صفحه اصلی بزنید و فارسی یا انگلیسی را انتخاب کنید.',
          ),
          _Section(
            title: 'دسترسی‌پذیری',
            body:
                'اپ با TalkBack هماهنگ است. دکمه‌ها برچسب صوتی دارند. دکمه میکروفون بزرگ طراحی شده تا استفاده برای افراد کم‌بینا و نابینا راحت‌تر باشد.',
          ),
          _Section(
            title: 'مجوز میکروفون',
            body:
                'برای ضبط صدا باید مجوز میکروفون را بدهید. اگر دکمه غیرفعال بود، از تنظیمات گوشی مجوز را فعال کنید.',
          ),
          _Section(
            title: 'نکته مهم',
            body:
                'در نسخه فعلی متن نمونه نمایش داده می‌شود. اتصال کامل موتور تشخیص گفتار واقعی در به‌روزرسانی‌های بعدی اضافه خواهد شد.',
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
