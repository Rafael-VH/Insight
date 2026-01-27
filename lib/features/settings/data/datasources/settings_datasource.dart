import 'dart:convert';

import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/settings/domain/entities/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SettingsDataSource {
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
  Future<void> resetSettings();
}

class SettingsDataSourceImpl implements SettingsDataSource {
  static const String _settingsKey = 'app_settings';
  final SharedPreferences sharedPreferences;

  SettingsDataSourceImpl({required this.sharedPreferences});

  @override
  Future<AppSettings> getSettings() async {
    try {
      final jsonString = sharedPreferences.getString(_settingsKey);

      if (jsonString == null) {
        return const AppSettings(); // Retornar configuración por defecto
      }

      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return AppSettings.fromJson(jsonMap);
    } catch (e) {
      throw FileSystemFailure('Error loading settings: ${e.toString()}');
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final jsonString = json.encode(settings.toJson());
      final success = await sharedPreferences.setString(
        _settingsKey,
        jsonString,
      );

      if (!success) {
        throw const FileSystemFailure('Failed to save settings');
      }
    } catch (e) {
      if (e is FileSystemFailure) {
        rethrow;
      }
      throw FileSystemFailure('Error saving settings: ${e.toString()}');
    }
  }

  @override
  Future<void> resetSettings() async {
    try {
      final success = await sharedPreferences.remove(_settingsKey);

      if (!success) {
        throw const FileSystemFailure('Failed to reset settings');
      }
    } catch (e) {
      throw FileSystemFailure('Error resetting settings: ${e.toString()}');
    }
  }
}
