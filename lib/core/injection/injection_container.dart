import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_it/get_it.dart';

// ── Navigation ───────────────────────────────────────────────────
import 'package:insight/features/navigation/presentation/bloc/navigation_bloc.dart';

// ── Settings — Data ──────────────────────────────────────────────
import 'package:insight/features/settings/data/datasources/settings_datasource.dart';
import 'package:insight/features/settings/data/datasources/theme_datasource.dart';
import 'package:insight/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:insight/features/settings/data/repositories/theme_repository_impl.dart';

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
import 'package:insight/features/stats/data/datasources/local_storage_datasource.dart';
import 'package:insight/features/stats/data/datasources/ocr_datasource.dart';
import 'package:insight/features/stats/data/datasources/json_export_datasource.dart';
import 'package:insight/features/stats/data/repositories/ocr_repository_impl.dart';
import 'package:insight/features/stats/data/repositories/stats_repository_impl.dart';

// ── Stats — Domain ────────────────────────────────────────────────
import 'package:insight/features/stats/domain/repositories/ocr_repository.dart';
import 'package:insight/features/stats/domain/repositories/stats_repository.dart';
import 'package:insight/features/stats/domain/repositories/theme_repository.dart';
import 'package:insight/features/stats/domain/usecases/copy_text_to_clipboard.dart';
import 'package:insight/features/stats/domain/usecases/export_stats_to_json.dart';
import 'package:insight/features/stats/domain/usecases/get_all_stats_collections.dart';
import 'package:insight/features/stats/domain/usecases/get_latest_stats_collection.dart';
import 'package:insight/features/stats/domain/usecases/import_stats_from_json.dart';
import 'package:insight/features/stats/domain/usecases/pick_image_and_recognize_text.dart';
import 'package:insight/features/stats/domain/usecases/save_collections_batch.dart';
import 'package:insight/features/stats/domain/usecases/save_stats_collection.dart';
import 'package:insight/features/stats/domain/usecases/update_stats_collection_name.dart';

// ── Stats — Presentation ──────────────────────────────────────────
import 'package:insight/features/stats/presentation/bloc/stats/stats_bloc.dart';
import 'package:insight/features/stats/presentation/bloc/ocr/ocr_bloc.dart';

// ── Heroes — Data ─────────────────────────────────────────────────
import 'package:insight/features/heroes/data/datasources/hero_cache_datasource.dart';
import 'package:insight/features/heroes/data/datasources/hero_remote_datasource.dart';
import 'package:insight/features/heroes/data/repositories/hero_repository_impl.dart';

// ── Heroes — Domain ───────────────────────────────────────────────
import 'package:insight/features/heroes/domain/repositories/hero_repository.dart';
import 'package:insight/features/heroes/domain/usecases/get_heroes.dart';
import 'package:insight/features/heroes/domain/usecases/get_hero_detail.dart';

// ── Heroes — Bloc ───────────────────────────────────────────────────
import 'package:insight/features/heroes/presentation/bloc/hero_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ================================================================
  // EXTERNAL
  // ================================================================

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => ImagePicker());
  sl.registerLazySingleton(
    () => TextRecognizer(script: TextRecognitionScript.latin),
  );

  // ================================================================
  // THEME
  // ================================================================

  // Data
  sl.registerLazySingleton<ThemeDataSource>(
    () => ThemeDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<ThemeRepository>(
    () => ThemeRepositoryImpl(dataSource: sl()),
  );

  // Presentation
  sl.registerFactory(
    () => ThemeBloc(settingsRepository: sl(), themeRepository: sl()),
  );

  // ================================================================
  // SETTINGS
  // ================================================================

  // Data
  sl.registerLazySingleton<SettingsDataSource>(
    () => SettingsDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(dataSource: sl()),
  );

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
  // STATS
  // ================================================================

  // Data
  sl.registerLazySingleton<LocalStorageDataSource>(
    () => LocalStorageDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<JsonExportDataSource>(
    () => JsonExportDataSourceImpl(),
  );
  sl.registerLazySingleton<StatsRepository>(
    () =>
        StatsRepositoryImpl(localDataSource: sl(), jsonExportDataSource: sl()),
  );

  // Domain — Use cases
  sl.registerLazySingleton(() => SaveStatsCollection(sl()));
  sl.registerLazySingleton(() => GetAllStatsCollections(sl()));
  sl.registerLazySingleton(() => GetLatestStatsCollection(sl()));
  sl.registerLazySingleton(() => UpdateStatsCollectionName(sl()));
  sl.registerLazySingleton(() => ExportStatsToJson(sl()));
  sl.registerLazySingleton(() => ImportStatsFromJson(sl()));
  sl.registerLazySingleton(() => SaveCollectionsBatch(sl()));

  // Presentation
  sl.registerFactory(
    () => StatsBloc(
      saveStatsCollection: sl(),
      getAllStatsCollections: sl(),
      getLatestStatsCollection: sl(),
      updateStatsCollectionName: sl(),
      statsRepository: sl(),
      exportStatsToJson: sl(),
      importStatsFromJson: sl(),
      saveCollectionsBatch: sl(),
    ),
  );

  // ================================================================
  // OCR
  // ================================================================

  // Data
  sl.registerLazySingleton<OcrDataSource>(
    () => OcrDataSourceImpl(imagePicker: sl(), textRecognizer: sl()),
  );
  sl.registerLazySingleton<OcrRepository>(
    () => OcrRepositoryImpl(dataSource: sl()),
  );

  // Domain — Use cases
  sl.registerLazySingleton(() => PickImageAndRecognizeText(sl()));
  sl.registerLazySingleton(() => CopyTextToClipboard(sl()));

  // Presentation
  sl.registerFactory(
    () => OcrBloc(pickImageAndRecognizeText: sl(), copyTextToClipboard: sl()),
  );

  // ================================================================
  // HEROES
  // ================================================================

  // Data
  sl.registerLazySingleton<HeroRemoteDataSource>(
    () => HeroRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<HeroCacheDataSource>(
    () => HeroCacheDataSourceImpl(prefs: sl<SharedPreferences>()),
  );
  // Singleton: el caché en memoria persiste entre navegaciones.
  sl.registerLazySingleton<HeroRepository>(
    () => HeroRepositoryImpl(remote: sl(), cache: sl()),
  );

  // Domain — Use cases
  sl.registerLazySingleton(() => GetHeroes(sl()));
  sl.registerLazySingleton(() => GetHeroDetail(sl()));

  // Presentation
  //
  // HeroBloc es Singleton para que:
  //   1. La lista no se pierda al entrar al detalle y volver.
  //   2. El detalle ya cargado se cachee mientras la pantalla
  //      permanezca en el stack de navegación.
  //
  // Si necesitas un detalle completamente fresco en cada apertura,
  // usa registerFactory() en su lugar.
  sl.registerLazySingleton(
    () => HeroBloc(getHeroes: sl(), getHeroDetail: sl()),
  );

  // ================================================================
  // NAVIGATION
  // ================================================================

  sl.registerFactory(() => NavigationBloc(totalDestinations: 7));
}
