import 'package:flutter/material.dart';

/// Entidad que representa un tema personalizado de la aplicación
class AppTheme {
  final String id;
  final String name;
  final ColorScheme lightColorScheme;
  final ColorScheme darkColorScheme;
  final bool isCustom;

  const AppTheme({
    required this.id,
    required this.name,
    required this.lightColorScheme,
    required this.darkColorScheme,
    this.isCustom = false,
  });

  AppTheme copyWith({
    String? id,
    String? name,
    ColorScheme? lightColorScheme,
    ColorScheme? darkColorScheme,
    bool? isCustom,
  }) {
    return AppTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      lightColorScheme: lightColorScheme ?? this.lightColorScheme,
      darkColorScheme: darkColorScheme ?? this.darkColorScheme,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lightColorScheme': _colorSchemeToJson(lightColorScheme),
      'darkColorScheme': _colorSchemeToJson(darkColorScheme),
      'isCustom': isCustom,
    };
  }

  factory AppTheme.fromJson(Map<String, dynamic> json) {
    return AppTheme(
      id: json['id'] as String,
      name: json['name'] as String,
      lightColorScheme: _colorSchemeFromJson(
        json['lightColorScheme'] as Map<String, dynamic>,
      ),
      darkColorScheme: _colorSchemeFromJson(
        json['darkColorScheme'] as Map<String, dynamic>,
      ),
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> _colorSchemeToJson(ColorScheme scheme) {
    return {
      'primary': scheme.primary.toARGB32(),
      'onPrimary': scheme.onPrimary.toARGB32(),
      'secondary': scheme.secondary.toARGB32(),
      'onSecondary': scheme.onSecondary.toARGB32(),
      'error': scheme.error.toARGB32(),
      'onError': scheme.onError.toARGB32(),
      'surface': scheme.surface.toARGB32(),
      'onSurface': scheme.onSurface.toARGB32(),
      'brightness': scheme.brightness.name,
    };
  }

  static ColorScheme _colorSchemeFromJson(Map<String, dynamic> json) {
    return ColorScheme(
      primary: Color(json['primary'] as int),
      onPrimary: Color(json['onPrimary'] as int),
      secondary: Color(json['secondary'] as int),
      onSecondary: Color(json['onSecondary'] as int),
      error: Color(json['error'] as int),
      onError: Color(json['onError'] as int),
      surface: Color(json['surface'] as int),
      onSurface: Color(json['onSurface'] as int),
      brightness: json['brightness'] == 'dark'
          ? Brightness.dark
          : Brightness.light,
    );
  }
}

/// Temas predefinidos de la aplicación
class AppThemes {
  AppThemes._();

  // Tema Verde (Default - Mobile Legends)
  static final AppTheme emerald = AppTheme(
    id: 'emerald',
    name: 'Esmeralda',
    lightColorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF059669),
      brightness: Brightness.light,
    ),
    darkColorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF059669),
      brightness: Brightness.dark,
    ),
  );

  // Tema Morado (Gaming)
  static final AppTheme violet = AppTheme(
    id: 'violet',
    name: 'Violeta',
    lightColorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C3AED),
      brightness: Brightness.light,
    ),
    darkColorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C3AED),
      brightness: Brightness.dark,
    ),
  );

  // Tema Azul (Clásico)
  static final AppTheme blue = AppTheme(
    id: 'blue',
    name: 'Azul Océano',
    lightColorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.light,
    ),
    darkColorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.dark,
    ),
  );

  // Tema Rojo (Ranked)
  static final AppTheme crimson = AppTheme(
    id: 'crimson',
    name: 'Carmesí',
    lightColorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFDC2626),
      brightness: Brightness.light,
    ),
    darkColorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFDC2626),
      brightness: Brightness.dark,
    ),
  );

  // Tema Naranja (Energía)
  static final AppTheme amber = AppTheme(
    id: 'amber',
    name: 'Ámbar',
    lightColorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFF59E0B),
      brightness: Brightness.light,
    ),
    darkColorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFF59E0B),
      brightness: Brightness.dark,
    ),
  );

  // Tema Rosa (Suave)
  static final AppTheme rose = AppTheme(
    id: 'rose',
    name: 'Rosa',
    lightColorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFEC4899),
      brightness: Brightness.light,
    ),
    darkColorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFEC4899),
      brightness: Brightness.dark,
    ),
  );

  // Lista de todos los temas disponibles
  static final List<AppTheme> all = [
    emerald,
    violet,
    blue,
    crimson,
    amber,
    rose,
  ];

  // Obtener tema por ID
  static AppTheme? getById(String id) {
    try {
      return all.firstWhere((theme) => theme.id == id);
    } catch (e) {
      return null;
    }
  }

  // Tema por defecto
  static AppTheme get defaultTheme => emerald;
}
