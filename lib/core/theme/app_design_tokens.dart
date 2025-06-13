import 'package:flutter/material.dart';
import 'dart:io' show Platform;

// Extension to safely use AnimationController methods
extension SafeAnimationController on AnimationController {
  /// Safely calls forward() with try-catch to handle disposed controllers
  TickerFuture? safeForward({double? from}) {
    try {
      return forward(from: from);
    } catch (e) {
      // Controller might be disposed, ignore the call
      return null;
    }
  }
  
  /// Safely calls reverse() with try-catch to handle disposed controllers
  TickerFuture? safeReverse({double? from}) {
    try {
      return reverse(from: from);
    } catch (e) {
      // Controller might be disposed, ignore the call
      return null;
    }
  }
  
  /// Safely calls repeat() with try-catch to handle disposed controllers
  TickerFuture? safeRepeat({bool reverse = false, double? min, double? max, Duration? period}) {
    try {
      return repeat(reverse: reverse, min: min, max: max, period: period);
    } catch (e) {
      // Controller might be disposed, ignore the call
      return null;
    }
  }
  
  /// Safely calls stop() with try-catch to handle disposed controllers
  void safeStop({bool canceled = true}) {
    try {
      stop(canceled: canceled);
    } catch (e) {
      // Controller might be disposed, ignore the call
    }
  }
  
  /// Safely calls reset() with try-catch to handle disposed controllers
  void safeReset() {
    try {
      reset();
    } catch (e) {
      // Controller might be disposed, ignore the call
    }
  }
}

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

  // Micro Interaction Design Tokens
  static const Duration microFast = Duration(milliseconds: 100);
  static const Duration microMedium = Duration(milliseconds: 150);
  static const Duration microSlow = Duration(milliseconds: 200);
  
  // Scale values for interactive elements
  static const double scaleDown = 0.95;
  static const double scaleUp = 1.05;
  static const double scaleNormal = 1.0;
  
  // Haptic feedback timing
  static const Duration hapticDelay = Duration(milliseconds: 50);
  
  // Spring animation curves
  static const Curve springCurve = Curves.easeOutBack;
  static const Curve dampedCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  
  // Interaction states
  static const double interactionOpacityPressed = 0.8;
  static const double interactionOpacityDisabled = 0.5;
  static const double interactionOpacityLoading = 0.7;

  // Layered Shadow System
  static List<BoxShadow> get shadowLow => [
    // Primary depth shadow
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 10,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    // Subtle ambient shadow
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    // Primary depth shadow
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 15,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
    // Secondary depth shadow
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 8,
      offset: const Offset(0, 3),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get shadowHigh => [
    // Primary depth shadow
    BoxShadow(
      color: Colors.black.withOpacity(0.16),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    // Secondary depth shadow
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    // Ambient shadow
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get shadowXHigh => [
    // Primary depth shadow
    BoxShadow(
      color: Colors.black.withOpacity(0.20),
      blurRadius: 25,
      offset: const Offset(0, 12),
      spreadRadius: 0,
    ),
    // Secondary depth shadow
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
    // Ambient shadow
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 8,
      offset: const Offset(0, 3),
      spreadRadius: 0,
    ),
  ];

  // Colored shadows for priority/interactive elements
  static List<BoxShadow> coloredShadow(Color color, {double intensity = 0.15}) => [
    // Primary depth shadow
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 10,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    // Colored accent shadow
    BoxShadow(
      color: color.withOpacity(intensity),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  // Button-specific shadows
  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.10),
      blurRadius: 8,
      offset: const Offset(0, 3),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> buttonShadowPressed({Color? color}) => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 6,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
    if (color != null)
      BoxShadow(
        color: color.withOpacity(0.08),
        blurRadius: 10,
        offset: const Offset(0, 2),
        spreadRadius: 0,
      ),
  ];

  // Interactive element shadows with hover states
  static List<BoxShadow> interactiveShadow({
    double hoverFactor = 0.0, 
    Color? accentColor,
    bool isPressed = false,
  }) {
    if (isPressed) {
      return buttonShadowPressed(color: accentColor);
    }
    
    final baseOpacity = 0.08 + (hoverFactor * 0.04);
    final baseBlur = 8.0 + (hoverFactor * 8.0);
    final baseOffset = 2.0 + (hoverFactor * 4.0);
    
    return [
      BoxShadow(
        color: Colors.black.withOpacity(baseOpacity),
        blurRadius: baseBlur,
        offset: Offset(0, baseOffset),
        spreadRadius: 0,
      ),
      if (accentColor != null)
        BoxShadow(
          color: accentColor.withOpacity(0.1 + (hoverFactor * 0.05)),
          blurRadius: 16 + (hoverFactor * 8),
          offset: Offset(0, 6 + (hoverFactor * 2)),
          spreadRadius: 0,
        ),
    ];
  }

  // Dark theme shadows (adjusted for dark backgrounds)
  static List<BoxShadow> get shadowLowDark => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 10,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 6,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get shadowMediumDark => [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 15,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 8,
      offset: const Offset(0, 3),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get shadowHighDark => [
    BoxShadow(
      color: Colors.black.withOpacity(0.35),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.18),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 6,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
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
      elevation: 0, // We use custom shadows instead
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
      ),
      color: Colors.white,
      shadowColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0, // We use custom shadows instead
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
        ),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
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
      elevation: 0, // We use custom shadows instead
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
      ),
      color: neutral800,
      shadowColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0, // We use custom shadows instead
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
        ),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
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