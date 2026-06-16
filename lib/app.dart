import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/language_select_screen.dart';
import 'services/locale_service.dart';

class SnapIQApp extends StatelessWidget {
  const SnapIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: LocaleService.instance,
      child: Consumer<LocaleService>(
        builder: (context, localeService, _) {
          // Key changes only if language changes — forces full rebuild so all
          // already-built screens pick up the new strings.
          // Home is LanguageSelectScreen only on first ever launch; afterwards HomeScreen.
          return MaterialApp(
            key: ValueKey('app_${localeService.isEnglish}'),
            title: 'SnapIQ',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF00B4FF),
                brightness: Brightness.dark,
                surface: const Color(0xFF050A14),
              ),
              scaffoldBackgroundColor: const Color(0xFF050A14),
              fontFamily: 'Roboto',
            ),
            home: localeService.hasChosenLanguage
                ? const HomeScreen()
                : const LanguageSelectScreen(),
          );
        },
      ),
    );
  }
}
