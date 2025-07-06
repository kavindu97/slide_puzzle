import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Needed for orientation
import 'screens/splash_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Lock app to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown, // optional: allow upside-down portrait
  ]);

  await MobileAds.instance.initialize();

  runApp(const MaterialApp(
    home: SplashScreen(),
    debugShowCheckedModeBanner: false,
  ));
}
