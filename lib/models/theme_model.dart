import 'package:flutter/material.dart';

enum Priority {
  low,
  medium,
  high,
}

enum ThemeType {
  defaultLight,
  defaultDark,
  premiumGlassDark,
  premiumGlassLight,
  premiumNeon,
  premiumMinimal,
  professional,
}

class AppTheme {
  final ThemeType type;
  final String name;
  final String description;
  final bool isPremium;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color accentColor;
  final List<Color> gradientColors;
  final double blurRadius;
  final double glassOpacity;
  final Map<Priority, Color> priorityColors;

  const AppTheme({
    required this.type,
    required this.name,
    required this.description,
    required this.isPremium,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.accentColor,
    required this.gradientColors,
    required this.blurRadius,
    required this.glassOpacity,
    required this.priorityColors,
  });

  // Default light theme
  static const AppTheme defaultLight = AppTheme(
    type: ThemeType.defaultLight,
    name: 'Default Light',
    description: 'Clean and modern light theme',
    isPremium: false,
    primaryColor: Color(0xFF78A1E8),
    secondaryColor: Color(0xFFF5AC3D),
    backgroundColor: Color(0xFFD7CFC6),
    surfaceColor: Colors.white,
    textColor: Colors.black87,
    accentColor: Color(0xFF78A1E8),
    gradientColors: [Color(0xFF78A1E8), Color(0xFFF5AC3D)],
    blurRadius: 0,
    glassOpacity: 0,
    priorityColors: {
      Priority.low: Color(0xFF4CAF50),
      Priority.medium: Color(0xFFFFC107),
      Priority.high: Color(0xFFFF5722),
    },
  );

  // Default dark theme
  static const AppTheme defaultDark = AppTheme(
    type: ThemeType.defaultDark,
    name: 'Default Dark',
    description: 'Comfortable dark theme',
    isPremium: false,
    primaryColor: Color(0xFF78A1E8),
    secondaryColor: Color(0xFFF5AC3D),
    backgroundColor: Color(0xFF2C2C2C),
    surfaceColor: Color(0xFF3D3D3D),
    textColor: Colors.white,
    accentColor: Color(0xFF78A1E8),
    gradientColors: [Color(0xFF78A1E8), Color(0xFFF5AC3D)],
    blurRadius: 0,
    glassOpacity: 0,
    priorityColors: {
      Priority.low: Color(0xFF4CAF50),
      Priority.medium: Color(0xFFFFC107),
      Priority.high: Color(0xFFFF5722),
    },
  );

  // Premium Glass Dark theme
  static const AppTheme premiumGlassDark = AppTheme(
    type: ThemeType.premiumGlassDark,
    name: 'Glass Dark',
    description: 'Premium dark theme with glassmorphism effects',
    isPremium: true,
    primaryColor: Color(0xFF6C63FF),
    secondaryColor: Color(0xFFFF6584),
    backgroundColor: Color(0xFF1A1A2E),
    surfaceColor: Color(0x1AFFFFFF),
    textColor: Colors.white,
    accentColor: Color(0xFF6C63FF),
    gradientColors: [
      Color(0xFF6C63FF),
      Color(0xFFFF6584),
      Color(0xFF1A1A2E),
    ],
    blurRadius: 20,
    glassOpacity: 0.1,
    priorityColors: {
      Priority.low: Color(0xFF00E676),
      Priority.medium: Color(0xFFFFD600),
      Priority.high: Color(0xFFFF1744),
    },
  );

  // Premium Glass Light theme
  static const AppTheme premiumGlassLight = AppTheme(
    type: ThemeType.premiumGlassLight,
    name: 'Glass Light',
    description: 'Premium light theme with glassmorphism effects',
    isPremium: true,
    primaryColor: Color(0xFF6C63FF),
    secondaryColor: Color(0xFFFF6584),
    backgroundColor: Color(0xFFF5F5F5),
    surfaceColor: Color(0x1A000000),
    textColor: Color(0xFF1A1A2E),
    accentColor: Color(0xFF6C63FF),
    gradientColors: [
      Color(0xFF6C63FF),
      Color(0xFFFF6584),
      Color(0xFFF5F5F5),
    ],
    blurRadius: 20,
    glassOpacity: 0.1,
    priorityColors: {
      Priority.low: Color(0xFF00E676),
      Priority.medium: Color(0xFFFFD600),
      Priority.high: Color(0xFFFF1744),
    },
  );

  // Premium Neon theme
  static const AppTheme premiumNeon = AppTheme(
    type: ThemeType.premiumNeon,
    name: 'Neon',
    description: 'Vibrant neon theme with glowing effects',
    isPremium: true,
    primaryColor: Color(0xFF00F5FF),
    secondaryColor: Color(0xFFFF00FF),
    backgroundColor: Color(0xFF000000),
    surfaceColor: Color(0xFF1A1A1A),
    textColor: Colors.white,
    accentColor: Color(0xFF00F5FF),
    gradientColors: [
      Color(0xFF00F5FF),
      Color(0xFFFF00FF),
      Color(0xFF000000),
    ],
    blurRadius: 15,
    glassOpacity: 0.2,
    priorityColors: {
      Priority.low: Color(0xFF00FF00),
      Priority.medium: Color(0xFFFFFF00),
      Priority.high: Color(0xFFFF0000),
    },
  );

  // Premium Minimal theme
  static const AppTheme premiumMinimal = AppTheme(
    type: ThemeType.premiumMinimal,
    name: 'Minimal',
    description: 'Clean and minimal premium theme',
    isPremium: true,
    primaryColor: Color(0xFF2D3436),
    secondaryColor: Color(0xFF636E72),
    backgroundColor: Color(0xFFF5F6FA),
    surfaceColor: Colors.white,
    textColor: Color(0xFF2D3436),
    accentColor: Color(0xFF2D3436),
    gradientColors: [
      Color(0xFF2D3436),
      Color(0xFF636E72),
    ],
    blurRadius: 10,
    glassOpacity: 0.05,
    priorityColors: {
      Priority.low: Color(0xFF00B894),
      Priority.medium: Color(0xFFFDCB6E),
      Priority.high: Color(0xFFE17055),
    },
  );

  // Professional theme
  static const AppTheme professional = AppTheme(
    type: ThemeType.professional,
    name: 'Professional',
    description: 'Clean and professional theme with navy blue accents',
    isPremium: false,
    primaryColor: Color(0xFF1E40AF),
    secondaryColor: Color(0xFF3B82F6),
    backgroundColor: Color(0xFFFFFFFF),
    surfaceColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF374151),
    accentColor: Color(0xFFF97316),
    gradientColors: [
      Color(0xFF1E40AF),
      Color(0xFF3B82F6),
    ],
    blurRadius: 0,
    glassOpacity: 0,
    priorityColors: {
      Priority.low: Color(0xFF3B82F6),
      Priority.medium: Color(0xFFF97316),
      Priority.high: Color(0xFF1E40AF),
    },
  );

  // Get all available themes
  static List<AppTheme> get allThemes => [
    defaultLight,
    defaultDark,
    premiumGlassDark,
    premiumGlassLight,
    premiumNeon,
    premiumMinimal,
    professional,
  ];

  // Get theme by type
  static AppTheme getThemeByType(ThemeType type) {
    return allThemes.firstWhere((theme) => theme.type == type);
  }

  // Convert to ThemeData
  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        background: backgroundColor,
        surface: surfaceColor,
        onBackground: textColor,
        onSurface: textColor,
        brightness: type == ThemeType.defaultDark || 
                   type == ThemeType.premiumGlassDark || 
                   type == ThemeType.premiumNeon
            ? Brightness.dark
            : Brightness.light,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: surfaceColor.withOpacity(glassOpacity),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor.withOpacity(glassOpacity),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
        labelStyle: TextStyle(color: textColor.withOpacity(0.85)),
        hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
        floatingLabelStyle: TextStyle(color: textColor),
        iconColor: textColor,
        suffixIconColor: textColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 32,
          color: textColor,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: textColor,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: textColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textColor,
        ),
      ),
    );
  }
} 