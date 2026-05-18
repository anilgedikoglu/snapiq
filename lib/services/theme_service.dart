import 'package:flutter/material.dart';

class AppTheme {
  final String id;
  final String name;
  final Color primaryColor;
  final Color accentColor;
  final Color bgColor;

  const AppTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.accentColor,
    required this.bgColor,
  });
}

class ThemeService {
  static const List<AppTheme> themes = [
    AppTheme(
      id: 'neon',
      name: 'Neon',
      primaryColor: Color(0xFF00B4FF),
      accentColor: Color(0xFFBB86FC),
      bgColor: Color(0xFF050A14),
    ),
    AppTheme(
      id: 'cyber_blue',
      name: 'Siber Mavi',
      primaryColor: Color(0xFF00FFFF),
      accentColor: Color(0xFF0066FF),
      bgColor: Color(0xFF000D1A),
    ),
    AppTheme(
      id: 'purple_storm',
      name: 'Mor Fırtına',
      primaryColor: Color(0xFFCC00FF),
      accentColor: Color(0xFFFF00AA),
      bgColor: Color(0xFF0D0014),
    ),
    AppTheme(
      id: 'emerald',
      name: 'Zümrüt',
      primaryColor: Color(0xFF00E676),
      accentColor: Color(0xFF00BFA5),
      bgColor: Color(0xFF001A0D),
    ),
    AppTheme(
      id: 'sunset',
      name: 'Gün Batımı',
      primaryColor: Color(0xFFFF6D00),
      accentColor: Color(0xFFFFD600),
      bgColor: Color(0xFF1A0A00),
    ),
  ];

  static AppTheme getTheme(String id) {
    return themes.firstWhere(
      (t) => t.id == id,
      orElse: () => themes.first,
    );
  }

  static ThemeData buildThemeData(AppTheme appTheme) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: appTheme.primaryColor,
        brightness: Brightness.dark,
        surface: appTheme.bgColor,
      ),
      scaffoldBackgroundColor: appTheme.bgColor,
      fontFamily: 'Roboto',
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
