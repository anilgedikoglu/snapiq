import 'package:flutter/material.dart';

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
      ),
      home: Scaffold(
        body: Container(
          color: const Color(0xFF050A14),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SnapIQ',
                  style: TextStyle(
                    color: Color(0xFF00B4FF),
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  '✓ 29 Test Chain\n✓ Arcade Auto-Start\n✓ Global Leaderboard',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
