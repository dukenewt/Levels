import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme_model.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  static const String _premiumThemesKey = 'unlocked_premium_themes';

  late SharedPreferences _prefs;
  ThemeType _currentTheme = ThemeType.professional;
  final Set<ThemeType> _unlockedPremiumThemes = {};

  ThemeType get currentTheme => _currentTheme;
  Set<ThemeType> get unlockedPremiumThemes => _unlockedPremiumThemes;
  bool get isPremiumTheme => AppTheme.getThemeByType(_currentTheme).isPremium;

  // Initialize the provider
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadTheme();
    _loadUnlockedPremiumThemes();
  }

  // Load saved theme
  void _loadTheme() {
    final themeIndex = _prefs.getInt(_themeKey);
    if (themeIndex != null) {
      _currentTheme = ThemeType.values[themeIndex];
    }
  }

  // Load unlocked premium themes
  void _loadUnlockedPremiumThemes() {
    final themes = _prefs.getStringList(_premiumThemesKey);
    if (themes != null) {
      _unlockedPremiumThemes.addAll(
        themes.map((t) => ThemeType.values[int.parse(t)]),
      );
    }
  }

  // Save current theme
  Future<void> _saveTheme() async {
    await _prefs.setInt(_themeKey, _currentTheme.index);
  }

  // Save unlocked premium themes
  Future<void> _saveUnlockedPremiumThemes() async {
    await _prefs.setStringList(
      _premiumThemesKey,
      _unlockedPremiumThemes.map((t) => t.index.toString()).toList(),
    );
  }

  // Change theme
  Future<void> setTheme(ThemeType theme) async {
    if (theme == _currentTheme) return;

    final newTheme = AppTheme.getThemeByType(theme);
    if (newTheme.isPremium && !_unlockedPremiumThemes.contains(theme)) {
      throw Exception('Premium theme not unlocked');
    }

    _currentTheme = theme;
    await _saveTheme();
    notifyListeners();
  }

  // Unlock premium theme
  Future<void> unlockPremiumTheme(ThemeType theme) async {
    if (!AppTheme.getThemeByType(theme).isPremium) return;

    _unlockedPremiumThemes.add(theme);
    await _saveUnlockedPremiumThemes();
    notifyListeners();
  }

  // Check if theme is unlocked
  bool isThemeUnlocked(ThemeType theme) {
    final appTheme = AppTheme.getThemeByType(theme);
    return !appTheme.isPremium || _unlockedPremiumThemes.contains(theme);
  }

  // Get current theme data
  ThemeData get currentThemeData {
    return AppTheme.getThemeByType(_currentTheme).toThemeData();
  }

  // Get all available themes
  List<AppTheme> get availableThemes {
    return AppTheme.allThemes.where((theme) => isThemeUnlocked(theme.type)).toList();
  }

  // Get premium themes
  List<AppTheme> get premiumThemes {
    return AppTheme.allThemes.where((theme) => theme.isPremium).toList();
  }

  // Get unlocked premium themes
  List<AppTheme> get unlockedPremiumThemesList {
    return premiumThemes.where((theme) => _unlockedPremiumThemes.contains(theme.type)).toList();
  }
} 