import 'package:flutter/material.dart';

enum AppThemeMode {
  light('Claro', Icons.light_mode),
  dark('Oscuro', Icons.dark_mode),
  system('Sistema', Icons.brightness_auto);

  const AppThemeMode(this.displayName, this.icon);
  final String displayName;
  final IconData icon;

  ThemeMode get flutterThemeMode {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

class AppSettings {
  final AppThemeMode themeMode;
  final String selectedThemeId;
  final bool enableNotifications;
  final bool enableHapticFeedback;
  final bool autoSaveStats;
  final String language;
  final bool useAwesomeSnackbar; // Control de diálogos

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.selectedThemeId = 'emerald',
    this.enableNotifications = true,
    this.enableHapticFeedback = true,
    this.autoSaveStats = true,
    this.language = 'es',
    this.useAwesomeSnackbar = true, // Habilitado por defecto
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    String? selectedThemeId,
    bool? enableNotifications,
    bool? enableHapticFeedback,
    bool? autoSaveStats,
    String? language,
    bool? useAwesomeSnackbar,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      selectedThemeId: selectedThemeId ?? this.selectedThemeId,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      autoSaveStats: autoSaveStats ?? this.autoSaveStats,
      language: language ?? this.language,
      useAwesomeSnackbar: useAwesomeSnackbar ?? this.useAwesomeSnackbar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'selectedThemeId': selectedThemeId,
      'enableNotifications': enableNotifications,
      'enableHapticFeedback': enableHapticFeedback,
      'autoSaveStats': autoSaveStats,
      'language': language,
      'useAwesomeSnackbar': useAwesomeSnackbar,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      selectedThemeId: json['selectedThemeId'] as String? ?? 'emerald',
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      enableHapticFeedback: json['enableHapticFeedback'] as bool? ?? true,
      autoSaveStats: json['autoSaveStats'] as bool? ?? true,
      language: json['language'] as String? ?? 'es',
      useAwesomeSnackbar: json['useAwesomeSnackbar'] as bool? ?? true,
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
