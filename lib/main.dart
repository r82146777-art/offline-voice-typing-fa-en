import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/stt_service.dart';
import 'services/tts_service.dart';
import 'services/model_downloader.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const OfflineVoiceTypingApp());
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
        home: const HomeScreen(),
      ),
    );
  }
}
