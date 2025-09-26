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
  natural,
  cyanPinkTeal,
  // Epic reward themes
  oceanDepths,
  forestCanopy,
  sunsetGlow,
  // Level unlock themes (cosmetic colorways)
  crimsonWave,
  amberBlaze,
  emeraldMist,
  violetStorm,
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

  // ENHANCED Default Light - Modern blue to purple gradient
  static const AppTheme defaultLight = AppTheme(
    type: ThemeType.defaultLight,
    name: 'Ocean Breeze',
    description: 'Fresh and energizing light theme with ocean-to-sky gradients',
    isPremium: false,
    primaryColor: Color(0xFF4F46E5), // Indigo
    secondaryColor: Color(0xFF06B6D4), // Cyan
    backgroundColor: Color(0xFFF8FAFC), // Very light blue-grey
    surfaceColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF1E293B), // Dark slate
    accentColor: Color(0xFFF59E0B), // Amber for highlights
    gradientColors: [
      Color(0xFF4F46E5), // Indigo
      Color(0xFF7C3AED), // Purple
      Color(0xFF06B6D4), // Cyan
    ],
    blurRadius: 0,
    glassOpacity: 0,
    priorityColors: {
      Priority.low: Color(0xFF10B981), // Emerald
      Priority.medium: Color(0xFFF59E0B), // Amber
      Priority.high: Color(0xFFEF4444), // Red
    },
  );

  // ENHANCED Default Dark - Warm sunset gradient
  static const AppTheme defaultDark = AppTheme(
    type: ThemeType.defaultDark,
    name: 'Midnight Glow',
    description: 'Comfortable dark theme with warm sunset undertones',
    isPremium: false,
    primaryColor: Color(0xFF9597d8), // Lighter indigo for dark theme
    secondaryColor: Color(0xFFEC4899), // Pink
    backgroundColor: Color(0xFF0F172A), // Very dark slate
    surfaceColor: Color(0xFF1E293B), // Dark slate
    textColor: Color(0xFFF1F5F9), // Light slate
    accentColor: Color(0xFFFBBF24), // Yellow for highlights
    gradientColors: [
      Color(0xFF6366F1), // Indigo
      Color(0xFFEC4899), // Pink
      Color(0xFFF59E0B), // Amber
    ],
    blurRadius: 0,
    glassOpacity: 0,
    priorityColors: {
      Priority.low: Color(0xFF34D399), // Emerald
      Priority.medium: Color(0xFFFBBF24), // Yellow
      Priority.high: Color(0xFFF87171), // Light red
    },
  );

  // Keep your existing premium themes but with enhanced colors
  static const AppTheme premiumGlassDark = AppTheme(
    type: ThemeType.premiumGlassDark,
    name: 'Glass Dark',
    description: 'Premium dark theme with glassmorphism effects',
    isPremium: true,
    primaryColor: Color(0xFF8B5CF6), // Purple
    secondaryColor: Color(0xFF06B6D4), // Cyan
    backgroundColor: Color(0xFF0C0A1E), // Deep purple-black
    surfaceColor: Color(0x1AFFFFFF),
    textColor: Colors.white,
    accentColor: Color(0xFFFBBF24), // Gold accent
    gradientColors: [
      Color(0xFF8B5CF6), // Purple
      Color(0xFF06B6D4), // Cyan
      Color(0xFF10B981), // Emerald
    ],
    blurRadius: 20,
    glassOpacity: 0.1,
    priorityColors: {
      Priority.low: Color(0xFF10B981),
      Priority.medium: Color(0xFFFBBF24),
      Priority.high: Color(0xFFEF4444),
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

  // Professional theme with subtle gradients
  static const AppTheme professional = AppTheme(
    type: ThemeType.professional,
    name: 'Executive',
    description:
        'Sophisticated theme with subtle gradients for professional use',
    isPremium: false,
    primaryColor: Color(0xFF1E40AF), // Navy blue
    secondaryColor: Color(0xFF059669), // Emerald
    backgroundColor: Color(0xFFFAFAFA), // Off-white
    surfaceColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF374151), // Cool grey
    accentColor: Color(0xFFDC2626), // Red for important actions
    gradientColors: [
      Color(0xFF1E40AF), // Navy
      Color(0xFF3730A3), // Indigo
      Color(0xFF059669), // Emerald
    ],
    blurRadius: 0,
    glassOpacity: 0,
    priorityColors: {
      Priority.low: Color(0xFF059669),
      Priority.medium: Color(0xFFD97706),
      Priority.high: Color(0xFFDC2626),
    },
  );

  // Natural theme enhanced
  static const AppTheme natural = AppTheme(
    type: ThemeType.natural,
    name: 'Forest Path',
    description: 'Earthy and calming with nature-inspired gradients',
    isPremium: false,
    primaryColor: Color(0xFF059669), // Forest green
    secondaryColor: Color(0xFFc9e9c9), // Lime
    backgroundColor: Color(0xFFf9efd9), // Warm white
    surfaceColor: Color(0xFFf9efd9),
    textColor: Color(0xFF365314), // Dark green
    accentColor: Color(0xFFD97706), // Orange
    gradientColors: [
      Color(0xFF059669), // Forest green
      Color(0xFF84CC16), // Lime
      Color(0xFFEAB308), // Golden
    ],
    blurRadius: 0,
    glassOpacity: 0,
    priorityColors: {
      Priority.low: Color(0xFF84CC16),
      Priority.medium: Color(0xFFEAB308),
      Priority.high: Color(0xFFDC2626),
    },
  );

  // Cyan Pink Teal theme
  static const AppTheme cyanPinkTeal = AppTheme(
    type: ThemeType.cyanPinkTeal,
    name: 'Punk',
    description: 'Vibrant cyan, hot pink, and teal on deep navy',
    isPremium: false,
    primaryColor: Color(0xFF00D9FF),
    secondaryColor: Color(0xFFFF6B9D),
    backgroundColor: Color(0xFF16213E),
    surfaceColor: Color(0xFF1A1A2E),
    textColor: Colors.white,
    accentColor: Color(0xFF4ECDC4),
    gradientColors: [
      Color(0xFF00D9FF),
      Color(0xFFFF6B9D),
      Color(0xFF4ECDC4),
    ],
    blurRadius: 0,
    glassOpacity: 0,
    priorityColors: {
      Priority.low: Color(0xFF4ECDC4),
      Priority.medium: Color(0xFFFF6B9D),
      Priority.high: Color(0xFF00D9FF),
    },
  );

  // Level unlock themes (cosmetic colorways)
  // Level 2: Crimson Wave
  static const AppTheme crimsonWave = AppTheme(
    type: ThemeType.crimsonWave,
    name: 'Crimson Wave',
    description: 'Bold crimson and rose colorway',
    isPremium: true,
    primaryColor: Color(0xFFDC2626), // Red
    secondaryColor: Color(0xFFF87171), // Light red
    backgroundColor: Color(0xFFFEF2F2), // Very light red
    surfaceColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF7F1D1D), // Dark red
    accentColor: Color(0xFFF59E0B), // Amber accent
    gradientColors: [
      Color(0xFFDC2626), // Red
      Color(0xFFEF4444), // Bright red
      Color(0xFFF87171), // Light red
    ],
    blurRadius: 0,
    glassOpacity: 0,
    priorityColors: {
      Priority.low: Color(0xFF10B981), // Emerald
      Priority.medium: Color(0xFFF59E0B), // Amber
      Priority.high: Color(0xFFDC2626), // Red
    },
  );

  // Level 4: Amber Blaze
  static const AppTheme amberBlaze = AppTheme(
    type: ThemeType.amberBlaze,
    name: 'Amber Blaze',
    description: 'Warm amber and gold colorway',
    isPremium: true,
    primaryColor: Color(0xFFD97706), // Orange
    secondaryColor: Color(0xFFFBBF24), // Yellow
    backgroundColor: Color(0xFFFFFBEB), // Very light yellow
    surfaceColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF92400E), // Dark orange
    accentColor: Color(0xFFEF4444), // Red accent
    gradientColors: [
      Color(0xFFD97706), // Orange
      Color(0xFFF59E0B), // Amber
      Color(0xFFFBBF24), // Yellow
    ],
    blurRadius: 0,
    glassOpacity: 0,
    priorityColors: {
      Priority.low: Color(0xFF10B981), // Emerald
      Priority.medium: Color(0xFFF59E0B), // Amber
      Priority.high: Color(0xFFEF4444), // Red
    },
  );

  // Level 6: Emerald Mist
  static const AppTheme emeraldMist = AppTheme(
    type: ThemeType.emeraldMist,
    name: 'Emerald Mist',
    description: 'Fresh emerald and jade colorway',
    isPremium: true,
    primaryColor: Color(0xFF059669), // Emerald
    secondaryColor: Color(0xFF34D399), // Light emerald
    backgroundColor: Color(0xFFECFDF5), // Very light green
    surfaceColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF064E3B), // Dark green
    accentColor: Color(0xFFF59E0B), // Amber accent
    gradientColors: [
      Color(0xFF059669), // Emerald
      Color(0xFF10B981), // Green
      Color(0xFF34D399), // Light emerald
    ],
    blurRadius: 0,
    glassOpacity: 0,
    priorityColors: {
      Priority.low: Color(0xFF10B981), // Emerald
      Priority.medium: Color(0xFFF59E0B), // Amber
      Priority.high: Color(0xFFEF4444), // Red
    },
  );

  // Level 8: Violet Storm
  static const AppTheme violetStorm = AppTheme(
    type: ThemeType.violetStorm,
    name: 'Violet Storm',
    description: 'Deep violet and purple colorway',
    isPremium: true,
    primaryColor: Color(0xFF7C3AED), // Purple
    secondaryColor: Color(0xFFA855F7), // Light purple
    backgroundColor: Color(0xFFFAF5FF), // Very light purple
    surfaceColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF581C87), // Dark purple
    accentColor: Color(0xFFF59E0B), // Amber accent
    gradientColors: [
      Color(0xFF7C3AED), // Purple
      Color(0xFF8B5CF6), // Violet
      Color(0xFFA855F7), // Light purple
    ],
    blurRadius: 0,
    glassOpacity: 0,
    priorityColors: {
      Priority.low: Color(0xFF10B981), // Emerald
      Priority.medium: Color(0xFFF59E0B), // Amber
      Priority.high: Color(0xFFEF4444), // Red
    },
  );

  // Epic reward themes
  static const AppTheme oceanDepths = AppTheme(
    type: ThemeType.oceanDepths,
    name: 'Ocean Depths',
    description: 'A calming blue theme inspired by ocean depths',
    isPremium: true,
    primaryColor: Color(0xFF1565C0),
    secondaryColor: Color(0xFF0277BD),
    backgroundColor: Color(0xFF0D47A1),
    surfaceColor: Color(0xFF1976D2),
    textColor: Colors.white,
    accentColor: Color(0xFF03DAC6),
    gradientColors: [
      Color(0xFF1565C0),
      Color(0xFF0277BD),
      Color(0xFF03A9F4),
    ],
    blurRadius: 0,
    glassOpacity: 0,
    priorityColors: {
      Priority.low: Color(0xFF03DAC6),
      Priority.medium: Color(0xFF03A9F4),
      Priority.high: Color(0xFF0277BD),
    },
  );

  static const AppTheme forestCanopy = AppTheme(
    type: ThemeType.forestCanopy,
    name: 'Forest Canopy',
    description: 'An earthy green theme inspired by forest canopies',
    isPremium: true,
    primaryColor: Color(0xFF2E7D32),
    secondaryColor: Color(0xFF388E3C),
    backgroundColor: Color(0xFF1B5E20),
    surfaceColor: Color(0xFF2E7D32),
    textColor: Colors.white,
    accentColor: Color(0xFF8BC34A),
    gradientColors: [
      Color(0xFF2E7D32),
      Color(0xFF388E3C),
      Color(0xFF4CAF50),
    ],
    blurRadius: 0,
    glassOpacity: 0,
    priorityColors: {
      Priority.low: Color(0xFF8BC34A),
      Priority.medium: Color(0xFF4CAF50),
      Priority.high: Color(0xFF2E7D32),
    },
  );

  static const AppTheme sunsetGlow = AppTheme(
    type: ThemeType.sunsetGlow,
    name: 'Sunset Glow',
    description: 'A warm orange theme inspired by golden sunsets',
    isPremium: true,
    primaryColor: Color(0xFFF57C00),
    secondaryColor: Color(0xFFFF8F00),
    backgroundColor: Color(0xFFE65100),
    surfaceColor: Color(0xFFF57C00),
    textColor: Colors.white,
    accentColor: Color(0xFFFFC107),
    gradientColors: [
      Color(0xFFF57C00),
      Color(0xFFFF8F00),
      Color(0xFFFF9800),
    ],
    blurRadius: 0,
    glassOpacity: 0,
    priorityColors: {
      Priority.low: Color(0xFFFFC107),
      Priority.medium: Color(0xFFFF9800),
      Priority.high: Color(0xFFF57C00),
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
        natural,
        cyanPinkTeal,
        crimsonWave,
        amberBlaze,
        emeraldMist,
        violetStorm,
        oceanDepths,
        forestCanopy,
        sunsetGlow,
      ];

  // Get theme by type
  static AppTheme getThemeByType(ThemeType type) {
    return allThemes.firstWhere((theme) => theme.type == type);
  }

  // Enhanced ThemeData conversion with better gradient integration
  ThemeData toThemeData() {
    final isDark = type == ThemeType.defaultDark ||
        type == ThemeType.premiumGlassDark ||
        type == ThemeType.premiumNeon ||
        type == ThemeType.cyanPinkTeal ||
        type == ThemeType.oceanDepths ||
        type == ThemeType.forestCanopy ||
        type == ThemeType.sunsetGlow;

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
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),

      // Enhanced card theme with subtle gradients
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: surfaceColor,
      ),

      // Enhanced AppBar with gradient potential
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),

      // Better input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: textColor.withOpacity(0.8)),
        hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
      ),

      // Enhanced button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
        elevation: 4,
      ),

      // Enhanced text theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 32,
          color: textColor,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: textColor,
          letterSpacing: -0.25,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: textColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textColor,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textColor.withOpacity(0.8),
          height: 1.4,
        ),
      ),
    );
  }
}
