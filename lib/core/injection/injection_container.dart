import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_it/get_it.dart';

// ── Navigation ───────────────────────────────────────────────────
import 'package:insight/features/navigation/presentation/bloc/navigation_bloc.dart';

// ── Settings — Data ──────────────────────────────────────────────
import 'package:insight/features/settings/data/datasources/settings_datasource.dart';
import 'package:insight/features/settings/data/datasources/theme_datasource.dart';
import 'package:insight/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:insight/features/settings/data/repositories/app_theme_repository_impl.dart';

// ── Settings — Domain ─────────────────────────────────────────────
import 'package:insight/features/settings/domain/repositories/settings_repository.dart';
import 'package:insight/features/settings/domain/usecases/get_settings.dart';
import 'package:insight/features/settings/domain/usecases/reset_settings.dart';
import 'package:insight/features/settings/domain/usecases/save_settings.dart';
import 'package:insight/features/settings/domain/usecases/update_auto_save.dart';
import 'package:insight/features/settings/domain/usecases/update_awesome_snackbar.dart';
import 'package:insight/features/settings/domain/usecases/update_haptic_feedback.dart';
import 'package:insight/features/settings/domain/usecases/update_notifications.dart';
import 'package:insight/features/settings/domain/usecases/update_selected_theme.dart';
import 'package:insight/features/settings/domain/usecases/update_theme_mode.dart';

// ── Settings — Presentation ───────────────────────────────────────
import 'package:insight/features/settings/presentation/bloc/setting/settings_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/theme/theme_bloc.dart';

// ── Stats — Data ──────────────────────────────────────────────────
import 'package:insight/features/upload/data/datasources/local_storage_datasource.dart';
import 'package:insight/features/ocr/data/datasources/ocr_datasource.dart';
import 'package:insight/features/upload/data/datasources/json_export_datasource.dart';
import 'package:insight/features/ocr/data/repositories/ocr_repository_impl.dart';

// ── Stats — Domain ────────────────────────────────────────────────
import 'package:insight/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:insight/features/settings/domain/repositories/app_theme_repository.dart';
import 'package:insight/core/usecases/copy_to_clipboard.dart';
import 'package:insight/features/ocr/domain/usecases/recognize_image_text.dart';
import 'package:insight/features/upload/domain/usecases/save_game_session.dart';

// ── Stats — Presentation ──────────────────────────────────────────
import 'package:insight/features/ocr/presentation/bloc/ocr_bloc.dart';
import 'package:insight/features/upload/presentation/bloc/upload_bloc.dart';

// ── History — Data ────────────────────────────────────────────────
import 'package:insight/features/history/data/repositories/history_repository_impl.dart';

// ── History — Domain ──────────────────────────────────────────────
import 'package:insight/features/history/domain/repositories/history_repository.dart';
import 'package:insight/features/history/domain/usecases/export_stats_to_json.dart';
import 'package:insight/features/history/domain/usecases/get_all_stats_collections.dart';
import 'package:insight/features/history/domain/usecases/get_latest_stats_collection.dart';
import 'package:insight/features/history/domain/usecases/import_stats_from_json.dart';
import 'package:insight/features/history/domain/usecases/save_collections_batch.dart';
import 'package:insight/features/history/domain/usecases/update_stats_collection_name.dart';

// ── History — Presentation ────────────────────────────────────────
import 'package:insight/features/history/presentation/bloc/history_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ================================================================
  // EXTERNAL
  // ================================================================

  // SharedPreferences primero — es la base de todo
  late final SharedPreferences sharedPreferences;
  try {
    sharedPreferences = await SharedPreferences.getInstance();
    debugPrint('✓ SharedPreferences OK');
  } catch (e) {
    debugPrint('✗ SharedPreferences failed: $e');
    rethrow;
  }

  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => ImagePicker());

  // TextRecognizer — puede fallar si ML Kit no está disponible
  try {
    sl.registerLazySingleton(() => TextRecognizer(script: TextRecognitionScript.latin));
    debugPrint('✓ TextRecognizer registrado');
  } catch (e) {
    debugPrint('✗ TextRecognizer failed: $e');
    rethrow;
  }

  // ================================================================
  // THEME
  // ================================================================

  // Data
  sl.registerLazySingleton<ThemeDataSource>(() => ThemeDataSourceImpl(sharedPreferences: sl()));
  sl.registerLazySingleton<AppThemeRepository>(() => AppThemeRepositoryImpl(dataSource: sl()));

  // Presentation
  sl.registerFactory(() => ThemeBloc(settingsRepository: sl(), themeRepository: sl()));

  // ================================================================
  // SETTINGS
  // ================================================================

  // Data
  sl.registerLazySingleton<SettingsDataSource>(
    () => SettingsDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(dataSource: sl()));

  // Domain — Use cases
  sl.registerLazySingleton(() => GetSettings(sl()));
  sl.registerLazySingleton(() => SaveSettings(sl()));
  sl.registerLazySingleton(() => ResetSettings(sl()));
  sl.registerLazySingleton(() => UpdateThemeMode(sl()));
  sl.registerLazySingleton(() => UpdateSelectedTheme(sl()));
  sl.registerLazySingleton(() => UpdateNotifications(sl()));
  sl.registerLazySingleton(() => UpdateHapticFeedback(sl()));
  sl.registerLazySingleton(() => UpdateAutoSave(sl()));
  sl.registerLazySingleton(() => UpdateAwesomeSnackbar(sl()));

  // Presentation
  sl.registerFactory(() => SettingsBloc(repository: sl()));

  // ================================================================
  // SHARED DATA SOURCES
  // Registrados aquí porque tanto Stats como History los necesitan.
  // ================================================================

  // Data
  sl.registerLazySingleton<LocalStorageDataSource>(
    () => LocalStorageDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<JsonExportDataSource>(() => JsonExportDataSourceImpl());

  // ================================================================
  // HISTORY
  // ================================================================

  // Data
  sl.registerLazySingleton<HistoryRepository>(
    () => HistoryRepositoryImpl(localDataSource: sl(), jsonExportDataSource: sl()),
  );

  // Domain — Use cases
  sl.registerLazySingleton(() => GetAllStatsCollections(sl()));
  sl.registerLazySingleton(() => GetLatestStatsCollection(sl()));
  sl.registerLazySingleton(() => UpdateStatsCollectionName(sl()));
  sl.registerLazySingleton(() => ExportStatsToJson(sl()));
  sl.registerLazySingleton(() => ImportStatsFromJson(sl()));
  sl.registerLazySingleton(() => SaveCollectionsBatch(sl()));

  // Presentation
  // LazySingleton: la lista no se pierde al navegar entre tabs.
  sl.registerLazySingleton(
    () => HistoryBloc(
      getAllStatsCollections: sl(),
      getLatestStatsCollection: sl(),
      updateStatsCollectionName: sl(),
      exportStatsToJson: sl(),
      importStatsFromJson: sl(),
      saveCollectionsBatch: sl(),
      historyRepository: sl(),
    ),
  );

  // ================================================================
  // STATS
  // Solo mantiene SaveStatsCollection para el flujo post-OCR.
  // El resto se movió a History.
  // ================================================================

  sl.registerLazySingleton(() => SaveStatsCollection(sl<HistoryRepository>()));

  sl.registerFactory(() => UploadBloc(saveStatsCollection: sl(), historyBloc: sl()));

  // ================================================================
  // OCR
  // ================================================================

  // Data
  sl.registerLazySingleton<OcrDataSource>(
    () => OcrDataSourceImpl(imagePicker: sl(), textRecognizer: sl()),
  );
  sl.registerLazySingleton<OcrRepository>(() => OcrRepositoryImpl(dataSource: sl()));

  // Domain — Use cases
  sl.registerLazySingleton(() => RecognizeImageText(sl()));
  sl.registerLazySingleton(() => CopyToClipboard(sl()));

  // Presentation
  sl.registerFactory(() => OcrBloc(pickImageAndRecognizeText: sl(), copyTextToClipboard: sl()));

  // ================================================================
  // NAVIGATION
  // ================================================================

  sl.registerFactory(() => NavigationBloc(totalDestinations: 3));

  debugPrint('✓ Todos los servicios registrados');
}
