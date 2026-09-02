import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const channelUrl = 'https://t.me/Akademi_hamdel';

  Future<void> _openChannel() async {
    final uri = Uri.parse(channelUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('درباره ما'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Icon(
              Icons.groups_rounded,
              size: 72,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'گروه تکنولوژی همدل',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'گروه تکنولوژی همدل با هدف آموزش، هم‌افزایی و توسعه ابزارهای کاربردی برای جامعه فارسی‌زبان شکل گرفته است. '
            'ما باور داریم فناوری باید در دسترس همه باشد؛ از جمله افراد دارای معلولیت بینایی.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
          ),
          const SizedBox(height: 24),
          Text(
            'مدیران',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person),
            title: Text('رضا ایمان‌زاده'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person),
            title: Text('امیرحسین بابایی'),
          ),
          const SizedBox(height: 20),
          Text(
            'کانال آکادمی همدل',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            channelUrl,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _openChannel,
                  icon: const Icon(Icons.telegram),
                  label: const Text('ورود به کانال'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(const ClipboardData(text: channelUrl));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('لینک کپی شد')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('کپی لینک'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'نسخه ۰.۳.۰',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
