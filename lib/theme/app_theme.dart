import 'package:flutter/material.dart';

/// Warm Editorial design system for DateWise AI.
///
/// A premium, professional palette built around the requested cream #EAE2B7,
/// paired with a deep Prussian-blue primary and a warm-gold accent
/// (navy + cream + gold reads high-end and trustworthy):
///   Background #fbf8ec, Surface #eae2b7, Primary #003049,
///   Accent #e0a13a, Text #16252e.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFFBF8EC); // light warm cream
  static const Color surface = Color(0xFFEAE2B7); // requested cream / sand
  static const Color primary = Color(0xFF003049); // prussian blue
  static const Color accent = Color(0xFFE0A13A); // warm gold
  static const Color text = Color(0xFF16252E); // deep navy charcoal
  static const Color textMuted = Color(0xFF5E6B72);

  static const Color primaryDark = Color(0xFF00202F);
  static const Color cardBorder = Color(0xFFE3DBBE); // soft warm border

  /// Pricing card surfaces.
  static const Color flameTint = Color(0xFFF4EDD0); // deeper cream for popular card
  static const Color magnetDark = Color(0xFF003049); // navy for premium card
  static const Color magnetDarkBorder = Color(0xFF16435C);

  /// Primary brand gradient (navy → ocean) used on buttons, badges, avatars.
  static const LinearGradient romanticGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF2A6F97)],
  );

  /// Warm accent gradient for small gold highlights.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE0A13A), Color(0xFFEDC373)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF3ECCF), background],
  );
}

/// Spacing scale (8pt grid).
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 40;
  static const double xxl = 64;
}

class AppRadius {
  AppRadius._();
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.background,
      brightness: Brightness.light,
    );

    final textTheme = _buildTextTheme(base.textTheme);

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
        space: 1,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surface,
        side: BorderSide.none,
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    const display = 'serif'; // elegant fallback; swap for a real font asset later
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontFamily: display,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
            height: 1.05,
          ),
          displayMedium: base.displayMedium?.copyWith(
            fontFamily: display,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
            height: 1.1,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            color: AppColors.text,
            height: 1.5,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            color: AppColors.text,
            height: 1.5,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        )
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text);
  }
}
