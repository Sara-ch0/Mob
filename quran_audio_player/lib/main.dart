import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'services/audio_handler.dart';
import 'services/notification_service.dart';
import 'services/download_service.dart';
import 'providers/theme_provider.dart';
import 'utils/app_theme.dart';

late AudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();
  await DownloadService.init();

  audioHandler = await AudioService.init(
    builder: () => QuranAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.quranapp.player.channel',
      androidNotificationChannelName: 'Quran Audio',
      androidNotificationOngoing: true,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const _transitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: _FadeSlideTransitionBuilder(),
      TargetPlatform.iOS:     _FadeSlideTransitionBuilder(),
    },
  );

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme:      AppTheme.lightTheme.copyWith(pageTransitionsTheme: _transitions),
      darkTheme:  AppTheme.theme.copyWith(pageTransitionsTheme: _transitions),
      themeMode:  themeProvider.mode,
      home: const SplashScreen(),
    );
  }
}

/// Custom page transition: soft fade + 4% upward slide.
class _FadeSlideTransitionBuilder extends PageTransitionsBuilder {
  const _FadeSlideTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade =
        CurvedAnimation(parent: animation, curve: Curves.easeOut);
    final slide =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
    return FadeTransition(
        opacity: fade, child: SlideTransition(position: slide, child: child));
  }
}