import 'dart:convert';

//
import 'package:insight/core/errors/failures.dart';
//
import 'package:insight/features/stats/domain/entities/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ThemeDataSource {
  Future<List<AppTheme>> getAllThemes();
  Future<AppTheme?> getThemeById(String id);
  Future<void> saveCustomTheme(AppTheme theme);
  Future<void> deleteCustomTheme(String id);
  Future<List<AppTheme>> getCustomThemes();
}

class ThemeDataSourceImpl implements ThemeDataSource {
  static const String _customThemesKey = 'custom_themes';
  final SharedPreferences sharedPreferences;

  ThemeDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<AppTheme>> getAllThemes() async {
    try {
      // Obtener temas predefinidos
      final predefinedThemes = AppThemes.all;

      // Obtener temas personalizados
      final customThemes = await getCustomThemes();

      // Combinar ambas listas
      return [...predefinedThemes, ...customThemes];
    } catch (e) {
      throw FileSystemFailure('Error loading themes: ${e.toString()}');
    }
  }

  @override
  Future<AppTheme?> getThemeById(String id) async {
    try {
      // Buscar primero en temas predefinidos
      final predefinedTheme = AppThemes.getById(id);
      if (predefinedTheme != null) {
        return predefinedTheme;
      }

      // Buscar en temas personalizados
      final customThemes = await getCustomThemes();
      try {
        return customThemes.firstWhere((theme) => theme.id == id);
      } catch (e) {
        return null;
      }
    } catch (e) {
      throw FileSystemFailure('Error loading theme: ${e.toString()}');
    }
  }

  @override
  Future<void> saveCustomTheme(AppTheme theme) async {
    try {
      final customThemes = await getCustomThemes();

      // Remover tema con el mismo ID si existe
      customThemes.removeWhere((t) => t.id == theme.id);

      // Agregar el nuevo tema
      customThemes.add(theme);

      // Guardar
      final jsonList = customThemes.map((t) => t.toJson()).toList();
      final jsonString = json.encode(jsonList);

      final success = await sharedPreferences.setString(
        _customThemesKey,
        jsonString,
      );

      if (!success) {
        throw const FileSystemFailure('Failed to save custom theme');
      }
    } catch (e) {
      if (e is FileSystemFailure) {
        rethrow;
      }
      throw FileSystemFailure('Error saving custom theme: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteCustomTheme(String id) async {
    try {
      final customThemes = await getCustomThemes();

      // Remover el tema
      customThemes.removeWhere((t) => t.id == id);

      // Guardar
      final jsonList = customThemes.map((t) => t.toJson()).toList();
      final jsonString = json.encode(jsonList);

      final success = await sharedPreferences.setString(
        _customThemesKey,
        jsonString,
      );

      if (!success) {
        throw const FileSystemFailure('Failed to delete custom theme');
      }
    } catch (e) {
      if (e is FileSystemFailure) {
        rethrow;
      }
      throw FileSystemFailure('Error deleting custom theme: ${e.toString()}');
    }
  }

  @override
  Future<List<AppTheme>> getCustomThemes() async {
    try {
      final jsonString = sharedPreferences.getString(_customThemesKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = json.decode(jsonString) as List;

      return jsonList
          .map((jsonMap) => AppTheme.fromJson(jsonMap as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FileSystemFailure('Error loading custom themes: ${e.toString()}');
    }
  }
}
