import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/stats/domain/usecases/get_all_stats_collections.dart';
import 'package:insight/stats/domain/usecases/get_latest_stats_collection.dart';
import 'package:insight/stats/domain/usecases/save_stats_collection.dart';
import 'package:insight/stats/domain/usecases/usecase.dart';
import 'package:insight/stats/presentation/bloc/ml_stats_event.dart';
import 'package:insight/stats/presentation/bloc/ml_stats_state.dart';

class MLStatsBloc extends Bloc<MLStatsEvent, MLStatsState> {
  final SaveStatsCollection saveStatsCollection;
  final GetAllStatsCollections getAllStatsCollections;
  final GetLatestStatsCollection getLatestStatsCollection;

  MLStatsBloc({
    required this.saveStatsCollection,
    required this.getAllStatsCollections,
    required this.getLatestStatsCollection,
  }) : super(MLStatsInitial()) {
    on<SaveStatsCollectionEvent>(_onSaveStatsCollection);
    on<LoadAllStatsCollectionsEvent>(_onLoadAllStatsCollections);
    on<LoadLatestStatsCollectionEvent>(_onLoadLatestStatsCollection);
  }

  Future<void> _onSaveStatsCollection(
    SaveStatsCollectionEvent event,
    Emitter<MLStatsState> emit,
  ) async {
    try {
      print('\n🚀 INICIANDO GUARDADO DE ESTADÍSTICAS');
      print('📅 Fecha de creación: ${event.collection.createdAt}');
      print('📊 Modos disponibles: ${event.collection.availableStats.length}');

      // Validar que haya al menos una estadística
      if (!event.collection.hasAnyStats) {
        print('❌ No hay estadísticas para guardar');
        emit(
          const MLStatsError(
            'No hay estadísticas para guardar',
            errorDetails:
                'Debes cargar al menos una estadística antes de guardar.',
          ),
        );
        return;
      }

      emit(const MLStatsSaving('Guardando estadísticas...'));

      final result = await saveStatsCollection(event.collection);

      await result.fold(
        (failure) async {
          print('❌ ERROR al guardar: ${failure.message}');
          emit(
            MLStatsError(
              'Error al guardar estadísticas',
              errorDetails: failure.message,
            ),
          );
        },
        (_) async {
          print('✅ Estadísticas guardadas exitosamente');
          emit(const MLStatsSaved('Estadísticas guardadas correctamente'));

          // CRÍTICO: Esperar un momento antes de recargar
          await Future.delayed(const Duration(milliseconds: 300));

          // Recargar las colecciones automáticamente
          print('🔄 Recargando colecciones...');
          add(LoadAllStatsCollectionsEvent());
        },
      );
    } catch (e) {
      print('❌ ERROR INESPERADO: $e');
      emit(MLStatsError('Error inesperado', errorDetails: e.toString()));
    }
  }

  Future<void> _onLoadAllStatsCollections(
    LoadAllStatsCollectionsEvent event,
    Emitter<MLStatsState> emit,
  ) async {
    print('\n📚 CARGANDO TODAS LAS COLECCIONES');

    // Solo mostrar loading si no hay estado previo
    if (state is! MLStatsCollectionsLoaded) {
      emit(MLStatsLoading());
    }

    final result = await getAllStatsCollections(NoParams());

    result.fold(
      (failure) {
        print('❌ Error al cargar: ${failure.message}');
        emit(
          MLStatsError(
            'Error al cargar estadísticas',
            errorDetails: failure.message,
          ),
        );
      },
      (collections) {
        print('✅ Colecciones cargadas: ${collections.length}');

        // Imprimir detalles de cada colección
        for (int i = 0; i < collections.length; i++) {
          print(
            '  [$i] ${collections[i].createdAt} - ${collections[i].availableStats.length} modos',
          );
        }

        emit(MLStatsCollectionsLoaded(collections));
      },
    );
  }

  Future<void> _onLoadLatestStatsCollection(
    LoadLatestStatsCollectionEvent event,
    Emitter<MLStatsState> emit,
  ) async {
    print('\n🔍 CARGANDO ÚLTIMA COLECCIÓN');

    emit(MLStatsLoading());

    final result = await getLatestStatsCollection(NoParams());

    result.fold(
      (failure) {
        print('❌ Error al cargar última: ${failure.message}');
        emit(
          MLStatsError(
            'Error al cargar últimas estadísticas',
            errorDetails: failure.message,
          ),
        );
      },
      (collection) {
        if (collection != null) {
          print('✅ Última colección cargada: ${collection.createdAt}');
        } else {
          print('ℹ No hay colecciones');
        }
        emit(MLLatestStatsLoaded(collection));
      },
    );
  }
}
