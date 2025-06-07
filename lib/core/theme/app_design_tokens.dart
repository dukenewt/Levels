import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class AppDesignTokens {
  // Spacing
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space5 = 24.0;
  static const double space6 = 32.0;
  static const double space7 = 48.0;

  // Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  // Elevation
  static const double elevation1 = 1.0;
  static const double elevation2 = 4.0;
  static const double elevation3 = 8.0;
  static const double elevation4 = 16.0;

  // Animation Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);
}

class ProfessionalTheme {
  // Color Palette
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryVariant = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color accent = Color(0xFFF59E0B);

  // Neutral
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Skill Colors
  static const Map<String, Color> skillColors = {
    'focus': Color(0xFF6C63FF),
    'organization': Color(0xFF00BFAE),
    'creativity': Color(0xFFFF6584),
  };

  // Platform adaptivity
  static bool get isDesktop => Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  // Accessibility helpers
  static Color accessibleTextColor(Color background) {
    // Simple luminance check for contrast
    return background.computeLuminance() > 0.5 ? neutral900 : Colors.white;
  }

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: Colors.white,
      background: neutral50,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: neutral800,
      onBackground: neutral800,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.25, height: 1.3),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.4),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.15, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 1.5),
    ),
    cardTheme: CardTheme(
      elevation: AppDesignTokens.elevation2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
      ),
      color: Colors.white,
      shadowColor: neutral900.withOpacity(0.1),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: neutral800,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: neutral800),
    ),
    visualDensity: isDesktop ? VisualDensity.compact : VisualDensity.standard,
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: neutral800,
      background: neutral900,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: neutral100,
      onBackground: neutral100,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2, color: Colors.white),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.25, height: 1.3, color: Colors.white),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.4, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.15, height: 1.5, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 1.5, color: Colors.white),
    ),
    cardTheme: CardTheme(
      elevation: AppDesignTokens.elevation2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
      ),
      color: neutral800,
      shadowColor: Colors.black.withOpacity(0.2),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: neutral100,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: neutral100),
    ),
    visualDensity: isDesktop ? VisualDensity.compact : VisualDensity.standard,
  );
} 