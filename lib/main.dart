import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/stt_service.dart';
import 'services/tts_service.dart';
import 'services/model_downloader.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    runApp(const OfflineVoiceTypingApp());
  }, (error, stack) {
    debugPrint('Uncaught zone error: $error\n$stack');
  });
}

class OfflineVoiceTypingApp extends StatelessWidget {
  const OfflineVoiceTypingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ModelDownloader()),
        ChangeNotifierProvider(create: (_) => SttService()),
        Provider(create: (_) => TtsService()),
      ],
      child: MaterialApp(
        title: 'تایپ صوتی آفلاین',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF006A6A),
            brightness: Brightness.light,
          ),
          fontFamily: 'sans-serif',
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4DD0E1),
            brightness: Brightness.dark,
          ),
          fontFamily: 'sans-serif',
        ),
        builder: (context, child) {
          ErrorWidget.builder = (details) {
            return Material(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'خطای نمایش:\n${details.exceptionAsString()}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          };
          return child ?? const SizedBox.shrink();
        },
        home: const HomeScreen(),
      ),
    );
  }
}
