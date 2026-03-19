import 'package:equatable/equatable.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';

abstract class StatsEvent extends Equatable {
  const StatsEvent();

  @override
  List<Object?> get props => [];
}

class SaveStatsCollectionEvent extends StatsEvent {
  final StatsCollection collection;

  const SaveStatsCollectionEvent(this.collection);

  @override
  List<Object> get props => [collection];
}

class LoadAllStatsCollectionsEvent extends StatsEvent {}

class LoadLatestStatsCollectionEvent extends StatsEvent {}

class DeleteStatsCollectionEvent extends StatsEvent {
  final DateTime createdAt;

  const DeleteStatsCollectionEvent(this.createdAt);

  @override
  List<Object> get props => [createdAt];
}

class ClearAllStatsEvent extends StatsEvent {}

class UpdateStatsCollectionNameEvent extends StatsEvent {
  final DateTime createdAt;
  final String newName;

  const UpdateStatsCollectionNameEvent({
    required this.createdAt,
    required this.newName,
  });

  @override
  List<Object> get props => [createdAt, newName];
}

class GetStatsCollectionByDateEvent extends StatsEvent {
  final DateTime createdAt;

  const GetStatsCollectionByDateEvent(this.createdAt);

  @override
  List<Object> get props => [createdAt];
}

class ExportStatsToJsonEvent extends StatsEvent {
  /// Si es null se exportan todas las colecciones.
  final List<StatsCollection>? collections;
  const ExportStatsToJsonEvent({this.collections});

  @override
  List<Object?> get props => [collections];
}

class ImportStatsFromJsonEvent extends StatsEvent {
  final String filePath;
  final bool mergeWithExisting;

  const ImportStatsFromJsonEvent({
    required this.filePath,
    this.mergeWithExisting = true,
  });

  @override
  List<Object> get props => [filePath, mergeWithExisting];
}
