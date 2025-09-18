// lib/core/injection/injection_container.dart (ACTUALIZADO)
import 'package:get_it/get_it.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
// ML Stats feature
import 'package:insight/stats/data/datasources/local_storage_datasource.dart';
// OCR feature
import 'package:insight/stats/data/datasources/ocr_datasource.dart';
import 'package:insight/stats/data/repositories/ocr_repository_impl.dart';
import 'package:insight/stats/data/repositories/stats_repository_impl.dart';
import 'package:insight/stats/domain/repositories/ocr_repository.dart';
import 'package:insight/stats/domain/repositories/stats_repository.dart';
import 'package:insight/stats/domain/usecases/copy_text_to_clipboard.dart';
import 'package:insight/stats/domain/usecases/get_all_stats_collections.dart';
import 'package:insight/stats/domain/usecases/get_latest_stats_collection.dart';
import 'package:insight/stats/domain/usecases/pick_image_and_recognize_text.dart';
import 'package:insight/stats/domain/usecases/save_stats_collection.dart';
import 'package:insight/stats/presentation/bloc/ml_stats_bloc.dart';
import 'package:insight/stats/presentation/bloc/ocr_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - ML Stats
  // Bloc
  sl.registerFactory(
    () => MLStatsBloc(
      saveStatsCollection: sl(),
      getAllStatsCollections: sl(),
      getLatestStatsCollection: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SaveStatsCollection(sl()));
  sl.registerLazySingleton(() => GetAllStatsCollections(sl()));
  sl.registerLazySingleton(() => GetLatestStatsCollection(sl()));

  // Repository
  sl.registerLazySingleton<StatsRepository>(
    () => StatsRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<LocalStorageDataSource>(
    () => LocalStorageDataSourceImpl(sharedPreferences: sl()),
  );

  //! Features - OCR
  // Bloc
  sl.registerFactory(
    () => OcrBloc(pickImageAndRecognizeText: sl(), copyTextToClipboard: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => PickImageAndRecognizeText(sl()));
  sl.registerLazySingleton(() => CopyTextToClipboard(sl()));

  // Repository
  sl.registerLazySingleton<OcrRepository>(
    () => OcrRepositoryImpl(dataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<OcrDataSource>(
    () => OcrDataSourceImpl(imagePicker: sl(), textRecognizer: sl()),
  );

  //! External
  sl.registerLazySingleton(() => ImagePicker());
  sl.registerLazySingleton(
    () => TextRecognizer(script: TextRecognitionScript.latin),
  );

  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}
