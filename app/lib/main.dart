import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carboneye/screens/splash_screen.dart';
import 'package:carboneye/utils/constants.dart';

void main() {
  runApp(
    const ProviderScope(
      child: CarbonEyeApp(),
    ),
  );
}

class CarbonEyeApp extends StatelessWidget {
  const CarbonEyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarbonEye',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: kPrimaryAccentColor,
        scaffoldBackgroundColor: kBackgroundColor,
        fontFamily: 'Montserrat',
        textTheme: TextTheme(
          titleLarge: kSectionTitleStyle,
          bodyMedium: kBodyTextStyle,
          bodySmall: kSecondaryBodyTextStyle,
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
