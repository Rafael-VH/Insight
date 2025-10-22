// Packages
import 'package:get_it/get_it.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
// Blocs - Navigation
import 'package:insight/features/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:insight/features/settings/data/datasources/settings_datasource.dart';
import 'package:insight/features/settings/data/datasources/theme_datasource.dart';
import 'package:insight/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:insight/features/settings/data/repositories/theme_repository_impl.dart';
import 'package:insight/features/settings/domain/repositories/settings_repository.dart';
// NUEVOS: Use Cases de Settings
import 'package:insight/features/settings/domain/usecases/get_settings.dart';
import 'package:insight/features/settings/domain/usecases/reset_settings.dart';
import 'package:insight/features/settings/domain/usecases/save_settings.dart';
import 'package:insight/features/settings/domain/usecases/update_auto_save.dart';
import 'package:insight/features/settings/domain/usecases/update_awesome_snackbar.dart';
import 'package:insight/features/settings/domain/usecases/update_haptic_feedback.dart';
import 'package:insight/features/settings/domain/usecases/update_notifications.dart';
import 'package:insight/features/settings/domain/usecases/update_selected_theme.dart';
import 'package:insight/features/settings/domain/usecases/update_theme_mode.dart';
// Blocs - Settings
import 'package:insight/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/theme_bloc.dart';
// Data Sources
import 'package:insight/features/stats/data/datasources/local_storage_datasource.dart';
import 'package:insight/features/stats/data/datasources/ocr_datasource.dart';
// Repositories
import 'package:insight/features/stats/data/repositories/ocr_repository_impl.dart';
import 'package:insight/features/stats/data/repositories/stats_repository_impl.dart';
import 'package:insight/features/stats/domain/repositories/ocr_repository.dart';
import 'package:insight/features/stats/domain/repositories/stats_repository.dart';
import 'package:insight/features/stats/domain/repositories/theme_repository.dart';
// Use Cases
import 'package:insight/features/stats/domain/usecases/copy_text_to_clipboard.dart';
import 'package:insight/features/stats/domain/usecases/get_all_stats_collections.dart';
import 'package:insight/features/stats/domain/usecases/get_latest_stats_collection.dart';
import 'package:insight/features/stats/domain/usecases/pick_image_and_recognize_text.dart';
import 'package:insight/features/stats/domain/usecases/save_stats_collection.dart';
import 'package:insight/features/stats/domain/usecases/update_stats_collection_name.dart';
// Blocs - Stats
import 'package:insight/features/stats/presentation/bloc/ml_stats_bloc.dart';
import 'package:insight/features/stats/presentation/bloc/ocr_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ==================== SHARED PREFERENCES ====================
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // ==================== THEME SETUP ====================
  // Data source
  sl.registerLazySingleton<ThemeDataSource>(
    () => ThemeDataSourceImpl(sharedPreferences: sl()),
  );

  // Repository
  sl.registerLazySingleton<ThemeRepository>(
    () => ThemeRepositoryImpl(dataSource: sl()),
  );

  // ==================== SETTINGS SETUP ====================
  // Data source
  sl.registerLazySingleton<SettingsDataSource>(
    () => SettingsDataSourceImpl(sharedPreferences: sl()),
  );

  // Repository
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(dataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetSettings(sl()));
  sl.registerLazySingleton(() => SaveSettings(sl()));
  sl.registerLazySingleton(() => ResetSettings(sl()));
  sl.registerLazySingleton(() => UpdateThemeMode(sl()));
  sl.registerLazySingleton(() => UpdateSelectedTheme(sl()));
  sl.registerLazySingleton(() => UpdateNotifications(sl()));
  sl.registerLazySingleton(() => UpdateHapticFeedback(sl()));
  sl.registerLazySingleton(() => UpdateAutoSave(sl()));
  sl.registerLazySingleton(() => UpdateAwesomeSnackbar(sl()));

  // ==================== ML STATS SETUP ====================
  // Data sources
  sl.registerLazySingleton<LocalStorageDataSource>(
    () => LocalStorageDataSourceImpl(sharedPreferences: sl()),
  );

  // Repository
  sl.registerLazySingleton<StatsRepository>(
    () => StatsRepositoryImpl(localDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => SaveStatsCollection(sl()));
  sl.registerLazySingleton(() => GetAllStatsCollections(sl()));
  sl.registerLazySingleton(() => GetLatestStatsCollection(sl()));
  sl.registerLazySingleton(() => UpdateStatsCollectionName(sl()));

  // ==================== OCR SETUP ====================
  // Data sources
  sl.registerLazySingleton<OcrDataSource>(
    () => OcrDataSourceImpl(imagePicker: sl(), textRecognizer: sl()),
  );

  // Repository
  sl.registerLazySingleton<OcrRepository>(
    () => OcrRepositoryImpl(dataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => PickImageAndRecognizeText(sl()));
  sl.registerLazySingleton(() => CopyTextToClipboard(sl()));

  // ==================== EXTERNAL DEPENDENCIES ====================
  sl.registerLazySingleton(() => ImagePicker());
  sl.registerLazySingleton(
    () => TextRecognizer(script: TextRecognitionScript.latin),
  );

  // ==================== BLOCS (FACTORY - SE CREAN NUEVOS CADA VEZ) ====================

  // Settings Bloc
  sl.registerFactory(() => SettingsBloc(repository: sl()));

  // Theme Bloc
  sl.registerFactory(
    () => ThemeBloc(settingsRepository: sl(), themeRepository: sl()),
  );

  // Navigation Bloc
  sl.registerFactory(() => NavigationBloc(totalDestinations: 3));

  // ML Stats Bloc
  sl.registerFactory(
    () => MLStatsBloc(
      saveStatsCollection: sl(),
      getAllStatsCollections: sl(),
      getLatestStatsCollection: sl(),
      updateStatsCollectionName: sl(),
      statsRepository: sl(),
    ),
  );

  // OCR Bloc
  sl.registerFactory(
    () => OcrBloc(pickImageAndRecognizeText: sl(), copyTextToClipboard: sl()),
  );
}
