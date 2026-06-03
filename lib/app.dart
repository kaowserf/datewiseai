import 'package:flutter/material.dart';

import 'screens/landing_screen.dart';
import 'theme/app_theme.dart';

/// Root widget. The app always opens on the landing/home page; from there the
/// user enters coaching via "Start coaching" or by choosing a plan. Returning
/// users (with a saved tier) get a "Continue" shortcut in the landing app bar.
class DateWiseApp extends StatelessWidget {
  const DateWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DateWise AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LandingScreen(),
    );
  }
}
