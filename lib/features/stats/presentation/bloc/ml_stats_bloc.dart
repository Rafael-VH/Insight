import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/stats/domain/repositories/stats_repository.dart';
//
import 'package:insight/features/stats/domain/usecases/get_all_stats_collections.dart';
import 'package:insight/features/stats/domain/usecases/get_latest_stats_collection.dart';
import 'package:insight/features/stats/domain/usecases/save_stats_collection.dart';
import 'package:insight/features/stats/domain/usecases/update_stats_collection_name.dart';
import 'package:insight/features/stats/domain/usecases/usecase.dart';
//
import 'package:insight/features/stats/presentation/bloc/ml_stats_event.dart';
import 'package:insight/features/stats/presentation/bloc/ml_stats_state.dart';

class MLStatsBloc extends Bloc<MLStatsEvent, MLStatsState> {
  final SaveStatsCollection saveStatsCollection;
  final GetAllStatsCollections getAllStatsCollections;
  final GetLatestStatsCollection getLatestStatsCollection;
  final UpdateStatsCollectionName updateStatsCollectionName;
  final StatsRepository statsRepository; // Para operaciones directas

  MLStatsBloc({
    required this.saveStatsCollection,
    required this.getAllStatsCollections,
    required this.getLatestStatsCollection,
    required this.updateStatsCollectionName,
    required this.statsRepository,
  }) : super(MLStatsInitial()) {
    on<SaveStatsCollectionEvent>(_onSaveStatsCollection);
    on<LoadAllStatsCollectionsEvent>(_onLoadAllStatsCollections);
    on<LoadLatestStatsCollectionEvent>(_onLoadLatestStatsCollection);
    on<DeleteStatsCollectionEvent>(_onDeleteStatsCollection);
    on<ClearAllStatsEvent>(_onClearAllStats);

    // NUEVOS HANDLERS
    on<UpdateStatsCollectionNameEvent>(_onUpdateStatsCollectionName);
    on<GetStatsCollectionByDateEvent>(_onGetStatsCollectionByDate);
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
            '  [$i] ${collections[i].createdAt} - ${collections[i].availableStats.length} modos - "${collections[i].displayName}"',
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

  Future<void> _onDeleteStatsCollection(
    DeleteStatsCollectionEvent event,
    Emitter<MLStatsState> emit,
  ) async {
    print('\n🗑️ ELIMINANDO COLECCIÓN: ${event.createdAt}');

    emit(MLStatsLoading());

    final result = await statsRepository.deleteStatsCollection(event.createdAt);

    await result.fold(
      (failure) async {
        print('❌ Error al eliminar: ${failure.message}');
        emit(
          MLStatsError(
            'Error al eliminar estadísticas',
            errorDetails: failure.message,
          ),
        );
      },
      (_) async {
        print('✅ Colección eliminada exitosamente');
        emit(const MLStatsDeleted('Estadística eliminada correctamente'));

        await Future.delayed(const Duration(milliseconds: 300));

        print('🔄 Recargando colecciones...');
        add(LoadAllStatsCollectionsEvent());
      },
    );
  }

  Future<void> _onClearAllStats(
    ClearAllStatsEvent event,
    Emitter<MLStatsState> emit,
  ) async {
    print('\n🧹 LIMPIANDO TODAS LAS ESTADÍSTICAS');

    emit(MLStatsLoading());

    final result = await statsRepository.clearAllStats();

    result.fold(
      (failure) {
        print('❌ Error al limpiar: ${failure.message}');
        emit(
          MLStatsError(
            'Error al limpiar estadísticas',
            errorDetails: failure.message,
          ),
        );
      },
      (_) {
        print('✅ Todas las estadísticas eliminadas');
        emit(
          const MLStatsCleared('Todas las estadísticas han sido eliminadas'),
        );
        add(LoadAllStatsCollectionsEvent());
      },
    );
  }

  // ==================== NUEVOS HANDLERS ====================

  Future<void> _onUpdateStatsCollectionName(
    UpdateStatsCollectionNameEvent event,
    Emitter<MLStatsState> emit,
  ) async {
    print('\n✏️ ACTUALIZANDO NOMBRE DE COLECCIÓN');
    print('📅 Fecha: ${event.createdAt}');
    print('📝 Nuevo nombre: "${event.newName}"');

    // No emitir loading para no interrumpir la UI
    final params = UpdateNameParams(
      createdAt: event.createdAt,
      newName: event.newName,
    );

    final result = await updateStatsCollectionName(params);

    await result.fold(
      (failure) async {
        print('❌ Error al actualizar nombre: ${failure.message}');
        emit(
          MLStatsError(
            'Error al actualizar nombre',
            errorDetails: failure.message,
          ),
        );
      },
      (_) async {
        print('✅ Nombre actualizado exitosamente');
        emit(
          MLStatsNameUpdated(
            message: 'Nombre actualizado a "${event.newName}"',
            newName: event.newName,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 200));

        print('🔄 Recargando colecciones...');
        add(LoadAllStatsCollectionsEvent());
      },
    );
  }

  Future<void> _onGetStatsCollectionByDate(
    GetStatsCollectionByDateEvent event,
    Emitter<MLStatsState> emit,
  ) async {
    print('\n🔍 BUSCANDO COLECCIÓN POR FECHA: ${event.createdAt}');

    emit(MLStatsLoading());

    final result = await statsRepository.getStatsCollectionByDate(
      event.createdAt,
    );

    result.fold(
      (failure) {
        print('❌ Error al buscar colección: ${failure.message}');
        emit(
          MLStatsError(
            'Error al buscar estadística',
            errorDetails: failure.message,
          ),
        );
      },
      (collection) {
        if (collection != null) {
          print('✅ Colección encontrada');
        } else {
          print('❌ Colección no encontrada');
        }
        emit(MLStatsCollectionByDateLoaded(collection));
      },
    );
  }
}
