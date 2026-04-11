import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/history/presentation/bloc/history_bloc.dart';
import 'package:insight/features/history/presentation/bloc/history_event.dart';
import 'package:insight/features/upload/domain/usecases/save_stats_collection.dart';
import 'package:insight/features/upload/presentation/bloc/upload_event.dart';
import 'package:insight/features/upload/presentation/bloc/upload_state.dart';

/// BLoC del módulo Stats — post-refactor.
///
/// Su única responsabilidad es orquestar el guardado de una
/// [StatsCollection] nueva tras el flujo de OCR y notificar al
/// [HistoryBloc] para que recargue la lista.
///
/// Todo lo relacionado con el historial (carga, eliminación,
/// renombrado, export/import) vive ahora en [HistoryBloc].
class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final SaveStatsCollection saveStatsCollection;
  final HistoryBloc historyBloc;

  StatsBloc({required this.saveStatsCollection, required this.historyBloc})
    : super(StatsInitial()) {
    on<SaveStatsCollectionEvent>(_onSaveStatsCollection);
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
            errorDetails: 'Debes cargar al menos una estadística antes de guardar.',
          ),
        );
        return;
      }

      emit(const StatsSaving('Guardando estadísticas...'));

      final result = await saveStatsCollection(event.collection);

      await result.fold(
        (failure) async {
          emit(StatsError('Error al guardar estadísticas', errorDetails: failure.message));
        },
        (_) async {
          emit(const StatsSaved('Estadísticas guardadas correctamente'));

          // Notificar al HistoryBloc para que recargue la lista.
          historyBloc.add(LoadAllStatsCollectionsEvent());
        },
      );
    } catch (e) {
      emit(StatsError('Error inesperado', errorDetails: e.toString()));
    }
  }
}
