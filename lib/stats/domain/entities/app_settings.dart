import 'package:flutter/material.dart';

enum AppThemeMode {
  light('Claro', Icons.light_mode),
  dark('Oscuro', Icons.dark_mode),
  system('Sistema', Icons.brightness_auto);

  const AppThemeMode(this.displayName, this.icon);
  final String displayName;
  final IconData icon;
}

class AppSettings {
  final AppThemeMode themeMode;
  final bool enableNotifications;
  final bool enableHapticFeedback;
  final bool autoSaveStats;
  final String language;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.enableNotifications = true,
    this.enableHapticFeedback = true,
    this.autoSaveStats = true,
    this.language = 'es',
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? enableNotifications,
    bool? enableHapticFeedback,
    bool? autoSaveStats,
    String? language,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      autoSaveStats: autoSaveStats ?? this.autoSaveStats,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'enableNotifications': enableNotifications,
      'enableHapticFeedback': enableHapticFeedback,
      'autoSaveStats': autoSaveStats,
      'language': language,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      enableNotifications: json['enableNotifications'] ?? true,
      enableHapticFeedback: json['enableHapticFeedback'] ?? true,
      autoSaveStats: json['autoSaveStats'] ?? true,
      language: json['language'] ?? 'es',
    );
  }

  ThemeMode get flutterThemeMode {
    switch (themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
