import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class ReflexIQApp extends StatelessWidget {
  const ReflexIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
