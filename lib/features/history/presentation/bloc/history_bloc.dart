import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/history/domain/usecases/export_stats_to_json.dart';
import 'package:insight/features/history/domain/usecases/get_all_stats_collections.dart';
import 'package:insight/features/history/domain/usecases/get_latest_stats_collection.dart';
import 'package:insight/features/history/domain/usecases/import_stats_from_json.dart';
import 'package:insight/features/history/domain/usecases/save_collections_batch.dart';
import 'package:insight/features/history/domain/usecases/update_stats_collection_name.dart';
import 'package:insight/features/history/domain/repositories/history_repository.dart';
import 'package:insight/features/history/presentation/bloc/history_event.dart';
import 'package:insight/features/history/presentation/bloc/history_state.dart';
import 'package:insight/features/upload/domain/entities/game_session.dart';

/// BLoC del módulo History.
///
/// Gestiona el ciclo de vida completo del historial de estadísticas:
/// carga, eliminación, renombrado, exportación e importación.
///
/// El guardado de una nueva colección post-OCR sigue siendo
/// responsabilidad del módulo `stats` ([StatsBloc.saveStatsCollection]).
/// Una vez guardada, este BLoC se encarga de recargar la lista.
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetAllStatsCollections getAllStatsCollections;
  final GetLatestStatsCollection getLatestStatsCollection;
  final UpdateStatsCollectionName updateStatsCollectionName;
  final ExportStatsToJson exportStatsToJson;
  final ImportStatsFromJson importStatsFromJson;
  final SaveCollectionsBatch saveCollectionsBatch;
  final HistoryRepository historyRepository;

  HistoryBloc({
    required this.getAllStatsCollections,
    required this.getLatestStatsCollection,
    required this.updateStatsCollectionName,
    required this.exportStatsToJson,
    required this.importStatsFromJson,
    required this.saveCollectionsBatch,
    required this.historyRepository,
  }) : super(HistoryInitial()) {
    on<LoadAllStatsCollectionsEvent>(_onLoadAll);
    on<LoadLatestStatsCollectionEvent>(_onLoadLatest);
    on<GetStatsCollectionByDateEvent>(_onGetByDate);
    on<DeleteStatsCollectionEvent>(_onDelete);
    on<ClearAllStatsEvent>(_onClearAll);
    on<UpdateStatsCollectionNameEvent>(_onUpdateName);
    on<ExportStatsToJsonEvent>(_onExport);
    on<ImportStatsFromJsonEvent>(_onImport);
  }

  // ── Carga ─────────────────────────────────────────────────────

  Future<void> _onLoadAll(LoadAllStatsCollectionsEvent event, Emitter<HistoryState> emit) async {
    // Evitar emitir Loading si ya hay datos en pantalla
    if (state is! HistoryCollectionsLoaded) {
      emit(HistoryLoading());
    }

    final result = await getAllStatsCollections();

    result.fold(
      (failure) =>
          emit(HistoryError('Error al cargar estadísticas', errorDetails: failure.message)),
      (collections) => emit(HistoryCollectionsLoaded(collections)),
    );
  }

  Future<void> _onLoadLatest(
    LoadLatestStatsCollectionEvent event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());

    final result = await getLatestStatsCollection();

    result.fold(
      (failure) =>
          emit(HistoryError('Error al cargar últimas estadísticas', errorDetails: failure.message)),
      (collection) => emit(HistoryLatestLoaded(collection)),
    );
  }

  Future<void> _onGetByDate(GetStatsCollectionByDateEvent event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());

    final result = await historyRepository.getStatsCollectionByDate(event.createdAt);

    result.fold(
      (failure) => emit(HistoryError('Error al buscar estadística', errorDetails: failure.message)),
      (collection) => emit(HistoryCollectionByDateLoaded(collection)),
    );
  }

  // ── Mutación ──────────────────────────────────────────────────

  Future<void> _onDelete(DeleteStatsCollectionEvent event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());

    final result = await historyRepository.deleteStatsCollection(event.createdAt);

    await result.fold(
      (failure) async =>
          emit(HistoryError('Error al eliminar estadísticas', errorDetails: failure.message)),
      (_) async {
        emit(const HistoryDeleted('Estadística eliminada correctamente'));
        await Future.delayed(const Duration(milliseconds: 300));
        add(LoadAllStatsCollectionsEvent());
      },
    );
  }

  Future<void> _onClearAll(ClearAllStatsEvent event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());

    final result = await historyRepository.clearAllStats();

    result.fold(
      (failure) =>
          emit(HistoryError('Error al limpiar estadísticas', errorDetails: failure.message)),
      (_) {
        emit(const HistoryCleared('Todas las estadísticas han sido eliminadas'));
        add(LoadAllStatsCollectionsEvent());
      },
    );
  }

  Future<void> _onUpdateName(
    UpdateStatsCollectionNameEvent event,
    Emitter<HistoryState> emit,
  ) async {
    final result = await updateStatsCollectionName(
      UpdateNameParams(createdAt: event.createdAt, newName: event.newName),
    );

    await result.fold(
      (failure) async =>
          emit(HistoryError('Error al actualizar nombre', errorDetails: failure.message)),
      (_) async {
        emit(
          HistoryNameUpdated(
            message: 'Nombre actualizado a "${event.newName}"',
            newName: event.newName,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 200));
        add(LoadAllStatsCollectionsEvent());
      },
    );
  }

  // ── Export / Import ──────────────────────────────────────────

  Future<void> _onExport(ExportStatsToJsonEvent event, Emitter<HistoryState> emit) async {
    emit(const HistoryExporting());

    List<StatsCollection> toExport = event.collections ?? [];

    if (toExport.isEmpty) {
      final loadResult = await getAllStatsCollections();
      toExport = loadResult.fold((_) => [], (list) => list);
    }

    if (toExport.isEmpty) {
      emit(
        const HistoryError(
          'No hay estadísticas para exportar',
          errorDetails: 'Guarda al menos una sesión antes de exportar.',
        ),
      );
      return;
    }

    final result = await exportStatsToJson(toExport);

    result.fold(
      (failure) => emit(HistoryError('Error al exportar', errorDetails: failure.message)),
      (filePath) => emit(HistoryExported(filePath: filePath, totalCollections: toExport.length)),
    );
  }

  Future<void> _onImport(ImportStatsFromJsonEvent event, Emitter<HistoryState> emit) async {
    emit(const HistoryImporting());

    final parseResult = await importStatsFromJson(event.filePath);

    await parseResult.fold(
      (failure) async =>
          emit(HistoryError('Error al leer el archivo', errorDetails: failure.message)),
      (importedCollections) async {
        final saveResult = await saveCollectionsBatch(
          importedCollections,
          replaceExisting: !event.mergeWithExisting,
        );

        saveResult.fold(
          (failure) => emit(HistoryError('Error al guardar', errorDetails: failure.message)),
          (savedCount) {
            final skipped = importedCollections.length - savedCount;
            emit(
              HistoryImported(
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
