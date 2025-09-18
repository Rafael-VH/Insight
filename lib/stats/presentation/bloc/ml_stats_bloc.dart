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
    emit(MLStatsLoading());

    final result = await saveStatsCollection(event.collection);

    result.fold(
      (failure) => emit(MLStatsError(failure.message)),
      (_) => emit(const MLStatsSaved('Estadísticas guardadas correctamente')),
    );
  }

  Future<void> _onLoadAllStatsCollections(
    LoadAllStatsCollectionsEvent event,
    Emitter<MLStatsState> emit,
  ) async {
    emit(MLStatsLoading());

    final result = await getAllStatsCollections(NoParams());

    result.fold(
      (failure) => emit(MLStatsError(failure.message)),
      (collections) => emit(MLStatsCollectionsLoaded(collections)),
    );
  }

  Future<void> _onLoadLatestStatsCollection(
    LoadLatestStatsCollectionEvent event,
    Emitter<MLStatsState> emit,
  ) async {
    emit(MLStatsLoading());

    final result = await getLatestStatsCollection(NoParams());

    result.fold(
      (failure) => emit(MLStatsError(failure.message)),
      (collection) => emit(MLLatestStatsLoaded(collection)),
    );
  }
}
