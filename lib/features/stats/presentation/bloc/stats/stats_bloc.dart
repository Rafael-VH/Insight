import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';
import 'package:insight/features/stats/domain/repositories/stats_repository.dart';
import 'package:insight/features/stats/domain/usecases/export_stats_to_json.dart';
import 'package:insight/features/stats/domain/usecases/get_all_stats_collections.dart';
import 'package:insight/features/stats/domain/usecases/get_latest_stats_collection.dart';
import 'package:insight/features/stats/domain/usecases/import_stats_from_json.dart';
import 'package:insight/features/stats/domain/usecases/save_collections_batch.dart';
import 'package:insight/features/stats/domain/usecases/save_stats_collection.dart';
import 'package:insight/features/stats/domain/usecases/update_stats_collection_name.dart';

import 'package:insight/features/stats/domain/usecases/usecase.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_event.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_state.dart';

class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final SaveStatsCollection saveStatsCollection;
  final GetAllStatsCollections getAllStatsCollections;
  final GetLatestStatsCollection getLatestStatsCollection;
  final UpdateStatsCollectionName updateStatsCollectionName;
  final StatsRepository statsRepository;
  final ExportStatsToJson exportStatsToJson;
  final ImportStatsFromJson importStatsFromJson;
  final SaveCollectionsBatch saveCollectionsBatch;

  StatsBloc({
    required this.saveStatsCollection,
    required this.getAllStatsCollections,
    required this.getLatestStatsCollection,
    required this.updateStatsCollectionName,
    required this.statsRepository,
    required this.exportStatsToJson,
    required this.importStatsFromJson,
    required this.saveCollectionsBatch,
  }) : super(StatsInitial()) {
    on<SaveStatsCollectionEvent>(_onSaveStatsCollection);
    on<LoadAllStatsCollectionsEvent>(_onLoadAllStatsCollections);
    on<LoadLatestStatsCollectionEvent>(_onLoadLatestStatsCollection);
    on<DeleteStatsCollectionEvent>(_onDeleteStatsCollection);
    on<ClearAllStatsEvent>(_onClearAllStats);
    on<UpdateStatsCollectionNameEvent>(_onUpdateStatsCollectionName);
    on<GetStatsCollectionByDateEvent>(_onGetStatsCollectionByDate);
    on<ExportStatsToJsonEvent>(_onExportStatsToJson);
    on<ImportStatsFromJsonEvent>(_onImportStatsFromJson);
  }

  Future<void> _onSaveStatsCollection(
    SaveStatsCollectionEvent event,
    Emitter<StatsState> emit,
  ) async {
    try {
      if (!event.collection.hasAnyStats) {
        emit(
          const StatsError(
            'No hay estadísticas para guardar',
            errorDetails:
                'Debes cargar al menos una estadística antes de guardar.',
          ),
        );
        return;
      }

      emit(const StatsSaving('Guardando estadísticas...'));

      final result = await saveStatsCollection(event.collection);

      await result.fold(
        (failure) async {
          emit(
            StatsError(
              'Error al guardar estadísticas',
              errorDetails: failure.message,
            ),
          );
        },
        (_) async {
          emit(const StatsSaved('Estadísticas guardadas correctamente'));

          await Future.delayed(const Duration(milliseconds: 300));

          add(LoadAllStatsCollectionsEvent());
        },
      );
    } catch (e) {
      emit(StatsError('Error inesperado', errorDetails: e.toString()));
    }
  }

  Future<void> _onLoadAllStatsCollections(
    LoadAllStatsCollectionsEvent event,
    Emitter<StatsState> emit,
  ) async {
    if (state is! StatsCollectionsLoaded) {
      emit(StatsLoading());
    }

    final result = await getAllStatsCollections(NoParams());

    result.fold(
      (failure) {
        emit(
          StatsError(
            'Error al cargar estadísticas',
            errorDetails: failure.message,
          ),
        );
      },
      (collections) {
        emit(StatsCollectionsLoaded(collections));
      },
    );
  }

  Future<void> _onLoadLatestStatsCollection(
    LoadLatestStatsCollectionEvent event,
    Emitter<StatsState> emit,
  ) async {
    emit(StatsLoading());

    final result = await getLatestStatsCollection(NoParams());

    result.fold(
      (failure) {
        emit(
          StatsError(
            'Error al cargar últimas estadísticas',
            errorDetails: failure.message,
          ),
        );
      },
      (collection) {
        emit(LatestStatsLoaded(collection));
      },
    );
  }

  Future<void> _onDeleteStatsCollection(
    DeleteStatsCollectionEvent event,
    Emitter<StatsState> emit,
  ) async {
    emit(StatsLoading());

    final result = await statsRepository.deleteStatsCollection(event.createdAt);

    await result.fold(
      (failure) async {
        emit(
          StatsError(
            'Error al eliminar estadísticas',
            errorDetails: failure.message,
          ),
        );
      },
      (_) async {
        emit(const StatsDeleted('Estadística eliminada correctamente'));

        await Future.delayed(const Duration(milliseconds: 300));

        add(LoadAllStatsCollectionsEvent());
      },
    );
  }

  Future<void> _onClearAllStats(
    ClearAllStatsEvent event,
    Emitter<StatsState> emit,
  ) async {
    emit(StatsLoading());

    final result = await statsRepository.clearAllStats();

    result.fold(
      (failure) {
        emit(
          StatsError(
            'Error al limpiar estadísticas',
            errorDetails: failure.message,
          ),
        );
      },
      (_) {
        emit(const StatsCleared('Todas las estadísticas han sido eliminadas'));
        add(LoadAllStatsCollectionsEvent());
      },
    );
  }

  Future<void> _onUpdateStatsCollectionName(
    UpdateStatsCollectionNameEvent event,
    Emitter<StatsState> emit,
  ) async {
    final params = UpdateNameParams(
      createdAt: event.createdAt,
      newName: event.newName,
    );

    final result = await updateStatsCollectionName(params);

    await result.fold(
      (failure) async {
        emit(
          StatsError(
            'Error al actualizar nombre',
            errorDetails: failure.message,
          ),
        );
      },
      (_) async {
        emit(
          StatsNameUpdated(
            message: 'Nombre actualizado a "${event.newName}"',
            newName: event.newName,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 200));

        add(LoadAllStatsCollectionsEvent());
      },
    );
  }

  Future<void> _onGetStatsCollectionByDate(
    GetStatsCollectionByDateEvent event,
    Emitter<StatsState> emit,
  ) async {
    emit(StatsLoading());

    final result = await statsRepository.getStatsCollectionByDate(
      event.createdAt,
    );

    result.fold(
      (failure) {
        emit(
          StatsError(
            'Error al buscar estadística',
            errorDetails: failure.message,
          ),
        );
      },
      (collection) {
        emit(StatsCollectionByDateLoaded(collection));
      },
    );
  }

  Future<void> _onExportStatsToJson(
    ExportStatsToJsonEvent event,
    Emitter<StatsState> emit,
  ) async {
    emit(const StatsExporting());

    List<StatsCollection> toExport = event.collections ?? [];

    if (toExport.isEmpty) {
      final loadResult = await getAllStatsCollections(NoParams());
      toExport = loadResult.fold((_) => [], (list) => list);
    }

    if (toExport.isEmpty) {
      emit(
        const StatsError(
          'No hay estadísticas para exportar',
          errorDetails: 'Guarda al menos una sesión antes de exportar.',
        ),
      );
      return;
    }

    final result = await exportStatsToJson(toExport);
    result.fold(
      (failure) =>
          emit(StatsError('Error al exportar', errorDetails: failure.message)),
      (filePath) => emit(
        StatsExported(filePath: filePath, totalCollections: toExport.length),
      ),
    );
  }

  Future<void> _onImportStatsFromJson(
    ImportStatsFromJsonEvent event,
    Emitter<StatsState> emit,
  ) async {
    emit(const StatsImporting());

    final parseResult = await importStatsFromJson(event.filePath);

    await parseResult.fold(
      (failure) async => emit(
        StatsError('Error al leer el archivo', errorDetails: failure.message),
      ),
      (importedCollections) async {
        final saveResult = await saveCollectionsBatch(
          importedCollections,
          replaceExisting: !event.mergeWithExisting,
        );

        saveResult.fold(
          (failure) => emit(
            StatsError('Error al guardar', errorDetails: failure.message),
          ),
          (savedCount) {
            final skipped = importedCollections.length - savedCount;
            emit(
              StatsImported(
                importedCount: savedCount,
                skippedCount: skipped,
                merged: event.mergeWithExisting,
              ),
            );
            Future.delayed(
              const Duration(milliseconds: 300),
              () => add(LoadAllStatsCollectionsEvent()),
            );
          },
        );
      },
    );
  }
}
