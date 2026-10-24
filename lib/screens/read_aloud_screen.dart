import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/tts_service.dart';

class ReadAloudScreen extends StatefulWidget {
  const ReadAloudScreen({super.key});

  @override
  State<ReadAloudScreen> createState() => _ReadAloudScreenState();
}

class _ReadAloudScreenState extends State<ReadAloudScreen> {
  final _controller = TextEditingController();
  bool _reading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    if (data?.text?.isNotEmpty == true) {
      setState(() => _controller.text = data!.text!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('متنی در حافظهٔ کپی وجود ندارد')),
      );
    }
  }

  Future<void> _speak() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا متن را وارد یا جای‌گذاری کنید')),
      );
      return;
    }
    setState(() => _reading = true);
    try {
      await context.read<TtsService>().speak(_controller.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خواندن متن انجام نشد: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  Future<void> _stop() async {
    await context.read<TtsService>().stop();
    if (mounted) setState(() => _reading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بلندخوانی متن')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'متن فارسی یا انگلیسی را بنویسید یا کپی کنید و جای‌گذاری کنید. زبان گفتار بر اساس متن انتخاب می‌شود. کیفیت و آفلاین بودن صدا به موتور گفتار و صداهای نصب‌شده روی گوشی بستگی دارد.',
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    labelText: 'متن برای بلندخوانی',
                    hintText: 'متن را اینجا بنویسید یا جای‌گذاری کنید',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _paste,
                    icon: const Icon(Icons.content_paste),
                    label: const Text('جای‌گذاری متن کپی‌شده'),
                  ),
                  FilledButton.icon(
                    onPressed: _reading ? null : _speak,
                    icon: const Icon(Icons.volume_up),
                    label: const Text('شروع بلندخوانی'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _stop,
                    icon: const Icon(Icons.stop),
                    label: const Text('توقف'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
