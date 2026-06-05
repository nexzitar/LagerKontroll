import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/app_config.dart';

/// Theme mode notifier that persists theme preference
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// Load theme mode from storage
  Future<void> _loadThemeMode() async {
    final box = await Hive.openBox(AppConfig.themeKey);
    final themeModeString = box.get(AppConfig.themeKey, defaultValue: 'system');

    switch (themeModeString) {
      case 'light':
        state = ThemeMode.light;
        break;
      case 'dark':
        state = ThemeMode.dark;
        break;
      default:
        state = ThemeMode.system;
    }
  }

  /// Save theme mode to storage
  Future<void> _saveThemeMode(ThemeMode mode) async {
    final box = await Hive.openBox(AppConfig.themeKey);
    String themeModeString;

    switch (mode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      case ThemeMode.system:
        themeModeString = 'system';
        break;
    }

    await box.put(AppConfig.themeKey, themeModeString);
  }

  /// Set theme mode to light
  Future<void> setLight() async {
    state = ThemeMode.light;
    await _saveThemeMode(ThemeMode.light);
  }

  /// Set theme mode to dark
  Future<void> setDark() async {
    state = ThemeMode.dark;
    await _saveThemeMode(ThemeMode.dark);
  }

  /// Set theme mode to system
  Future<void> setSystem() async {
    state = ThemeMode.system;
    await _saveThemeMode(ThemeMode.system);
  }

  /// Toggle between light and dark mode
  Future<void> toggle() async {
    if (state == ThemeMode.light) {
      await setDark();
    } else {
      await setLight();
    }
  }
}

/// Provider for theme mode
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);
