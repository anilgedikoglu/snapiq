import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'services/locale_service.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved language before UI renders
  await LocaleService.instance.load();

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

  runApp(const SnapIQApp());

  // Initialize AdMob (+ iOS ATT prompt) after the first frame so the
  // tracking permission dialog appears with the app in the foreground.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AdService().initialize();
  });
}
