import 'package:equatable/equatable.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';

abstract class StatsEvent extends Equatable {
  const StatsEvent();

  @override
  List<Object?> get props => [];
}

/// Guarda una nueva colección generada por el flujo OCR.
/// El resto de operaciones (carga, eliminación, export…)
/// se gestionan desde [HistoryBloc].
class SaveStatsCollectionEvent extends StatsEvent {
  final StatsCollection collection;

  const SaveStatsCollectionEvent(this.collection);

  @override
  List<Object> get props => [collection];
}
