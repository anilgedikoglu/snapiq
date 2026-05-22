import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'services/ad_service.dart';
import 'services/locale_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Dark system UI
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Ad service init (debug: logs only)
  await AdService().initialize();

  // Load saved language preference before anything renders
  try {
    await LocaleService.instance.load().timeout(const Duration(seconds: 2));
  } catch (e) {
    // If load fails or times out, continue with default (Turkish)
    debugPrint('LocaleService load timeout/error: $e');
  }

  runApp(const ReflexIQApp());
}
