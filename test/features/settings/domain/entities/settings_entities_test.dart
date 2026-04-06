import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insight/features/settings/domain/entities/app_settings.dart';
import 'package:insight/features/settings/domain/entities/app_theme.dart';

void main() {
  // ================================================================
  // AppSettings
  // ================================================================

  group('AppSettings', () {
    group('constructor por defecto', () {
      test('crea instancia con valores por defecto correctos', () {
        const settings = AppSettings();
        expect(settings.themeMode, equals(AppThemeMode.system));
        expect(settings.selectedThemeId, equals('emerald'));
        expect(settings.enableNotifications, isTrue);
        expect(settings.enableHapticFeedback, isTrue);
        expect(settings.autoSaveStats, isTrue);
        expect(settings.language, equals('es'));
        expect(settings.useAwesomeSnackbar, isTrue);
      });
    });

    group('copyWith', () {
      test('actualiza themeMode', () {
        const settings = AppSettings();
        final updated = settings.copyWith(themeMode: AppThemeMode.dark);
        expect(updated.themeMode, equals(AppThemeMode.dark));
        expect(updated.selectedThemeId, equals(settings.selectedThemeId));
      });

      test('actualiza selectedThemeId', () {
        const settings = AppSettings();
        final updated = settings.copyWith(selectedThemeId: 'violet');
        expect(updated.selectedThemeId, equals('violet'));
      });

      test('actualiza enableNotifications', () {
        const settings = AppSettings();
        final updated = settings.copyWith(enableNotifications: false);
        expect(updated.enableNotifications, isFalse);
      });

      test('actualiza useAwesomeSnackbar', () {
        const settings = AppSettings();
        final updated = settings.copyWith(useAwesomeSnackbar: false);
        expect(updated.useAwesomeSnackbar, isFalse);
      });

      test('no modifica otros campos al actualizar uno', () {
        const settings = AppSettings();
        final updated = settings.copyWith(language: 'en');
        expect(updated.themeMode, equals(settings.themeMode));
        expect(updated.autoSaveStats, equals(settings.autoSaveStats));
        expect(updated.enableHapticFeedback,
            equals(settings.enableHapticFeedback));
      });
    });

    group('toJson', () {
      test('serializa todos los campos', () {
        const settings = AppSettings();
        final json = settings.toJson();
        expect(json['themeMode'], equals(AppThemeMode.system.name));
        expect(json['selectedThemeId'], equals('emerald'));
        expect(json['enableNotifications'], isTrue);
        expect(json['enableHapticFeedback'], isTrue);
        expect(json['autoSaveStats'], isTrue);
        expect(json['language'], equals('es'));
        expect(json['useAwesomeSnackbar'], isTrue);
      });

      test('serializa themeMode como string', () {
        const settings = AppSettings(themeMode: AppThemeMode.dark);
        final json = settings.toJson();
        expect(json['themeMode'], equals('dark'));
      });
    });

    group('fromJson', () {
      test('deserializa correctamente un JSON válido', () {
        const original = AppSettings(
          themeMode: AppThemeMode.light,
          selectedThemeId: 'crimson',
          enableNotifications: false,
          enableHapticFeedback: false,
          autoSaveStats: false,
          language: 'en',
          useAwesomeSnackbar: false,
        );
        final json = original.toJson();
        final restored = AppSettings.fromJson(json);
        expect(restored.themeMode, equals(AppThemeMode.light));
        expect(restored.selectedThemeId, equals('crimson'));
        expect(restored.enableNotifications, isFalse);
        expect(restored.useAwesomeSnackbar, isFalse);
      });

      test('usa AppThemeMode.system como fallback para modo desconocido', () {
        final json = const AppSettings().toJson();
        json['themeMode'] = 'unknown_mode';
        final settings = AppSettings.fromJson(json);
        expect(settings.themeMode, equals(AppThemeMode.system));
      });

      test('usa valores por defecto para campos ausentes en el JSON', () {
        final settings = AppSettings.fromJson({});
        expect(settings.selectedThemeId, equals('emerald'));
        expect(settings.enableNotifications, isTrue);
        expect(settings.autoSaveStats, isTrue);
        expect(settings.useAwesomeSnackbar, isTrue);
      });

      test('ida y vuelta toJson → fromJson preserva los datos', () {
        const original = AppSettings(
          themeMode: AppThemeMode.dark,
          selectedThemeId: 'blue',
          enableNotifications: true,
          enableHapticFeedback: false,
          autoSaveStats: true,
          language: 'es',
          useAwesomeSnackbar: false,
        );
        final restored = AppSettings.fromJson(original.toJson());
        expect(restored.themeMode, equals(original.themeMode));
        expect(restored.selectedThemeId, equals(original.selectedThemeId));
        expect(restored.enableHapticFeedback,
            equals(original.enableHapticFeedback));
        expect(restored.useAwesomeSnackbar, equals(original.useAwesomeSnackbar));
      });
    });

    group('flutterThemeMode', () {
      test('light → ThemeMode.light', () {
        const settings = AppSettings(themeMode: AppThemeMode.light);
        expect(settings.flutterThemeMode, equals(ThemeMode.light));
      });

      test('dark → ThemeMode.dark', () {
        const settings = AppSettings(themeMode: AppThemeMode.dark);
        expect(settings.flutterThemeMode, equals(ThemeMode.dark));
      });

      test('system → ThemeMode.system', () {
        const settings = AppSettings(themeMode: AppThemeMode.system);
        expect(settings.flutterThemeMode, equals(ThemeMode.system));
      });
    });
  });

  // ================================================================
  // AppThemeMode
  // ================================================================

  group('AppThemeMode', () {
    test('todos los modos tienen displayName no vacío', () {
      for (final mode in AppThemeMode.values) {
        expect(mode.displayName, isNotEmpty);
      }
    });

    test('todos los modos tienen un IconData', () {
      for (final mode in AppThemeMode.values) {
        expect(mode.icon, isA<IconData>());
      }
    });

    test('flutterThemeMode retorna el valor correcto para cada modo', () {
      expect(AppThemeMode.light.flutterThemeMode, equals(ThemeMode.light));
      expect(AppThemeMode.dark.flutterThemeMode, equals(ThemeMode.dark));
      expect(AppThemeMode.system.flutterThemeMode, equals(ThemeMode.system));
    });
  });

  // ================================================================
  // AppTheme
  // ================================================================

  group('AppTheme', () {
    final sampleTheme = AppTheme(
      id: 'test_theme',
      name: 'Test Theme',
      lightColorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF059669),
        brightness: Brightness.light,
      ),
      darkColorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF059669),
        brightness: Brightness.dark,
      ),
      isCustom: false,
    );

    group('copyWith', () {
      test('actualiza el nombre', () {
        final updated = sampleTheme.copyWith(name: 'Nuevo Nombre');
        expect(updated.name, equals('Nuevo Nombre'));
        expect(updated.id, equals(sampleTheme.id));
      });

      test('actualiza isCustom', () {
        final updated = sampleTheme.copyWith(isCustom: true);
        expect(updated.isCustom, isTrue);
      });
    });

    group('toJson / fromJson', () {
      test('serializa y deserializa correctamente', () {
        final json = sampleTheme.toJson();
        final restored = AppTheme.fromJson(json);
        expect(restored.id, equals(sampleTheme.id));
        expect(restored.name, equals(sampleTheme.name));
        expect(restored.isCustom, equals(sampleTheme.isCustom));
      });

      test('toJson incluye todas las claves esperadas', () {
        final json = sampleTheme.toJson();
        for (final key in [
          'id',
          'name',
          'lightColorScheme',
          'darkColorScheme',
          'isCustom',
        ]) {
          expect(json.containsKey(key), isTrue, reason: 'falta clave: $key');
        }
      });

      test('lightColorScheme tiene el brightness correcto', () {
        final json = sampleTheme.toJson();
        final restored = AppTheme.fromJson(json);
        expect(restored.lightColorScheme.brightness, equals(Brightness.light));
      });

      test('darkColorScheme tiene el brightness correcto', () {
        final json = sampleTheme.toJson();
        final restored = AppTheme.fromJson(json);
        expect(restored.darkColorScheme.brightness, equals(Brightness.dark));
      });
    });
  });

  // ================================================================
  // AppThemes (temas predefinidos)
  // ================================================================

  group('AppThemes', () {
    test('all contiene exactamente 6 temas predefinidos', () {
      expect(AppThemes.all.length, equals(6));
    });

    test('defaultTheme es esmeralda', () {
      expect(AppThemes.defaultTheme.id, equals('emerald'));
    });

    test('getById retorna el tema correcto', () {
      final theme = AppThemes.getById('violet');
      expect(theme, isNotNull);
      expect(theme!.id, equals('violet'));
    });

    test('getById retorna null para ID inexistente', () {
      final theme = AppThemes.getById('no_existe');
      expect(theme, isNull);
    });

    test('todos los temas predefinidos tienen isCustom = false', () {
      for (final theme in AppThemes.all) {
        expect(theme.isCustom, isFalse,
            reason: 'el tema ${theme.id} no debería ser custom');
      }
    });

    test('todos los temas predefinidos tienen ID único', () {
      final ids = AppThemes.all.map((t) => t.id).toSet();
      expect(ids.length, equals(AppThemes.all.length));
    });
  });
}