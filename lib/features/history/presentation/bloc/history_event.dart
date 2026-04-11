import 'package:equatable/equatable.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

// ── Carga ─────────────────────────────────────────────────────────

class LoadAllStatsCollectionsEvent extends HistoryEvent {}

class LoadLatestStatsCollectionEvent extends HistoryEvent {}

class GetStatsCollectionByDateEvent extends HistoryEvent {
  final DateTime createdAt;

  const GetStatsCollectionByDateEvent(this.createdAt);

  @override
  List<Object> get props => [createdAt];
}

// ── Mutación ──────────────────────────────────────────────────────

class DeleteStatsCollectionEvent extends HistoryEvent {
  final DateTime createdAt;

  const DeleteStatsCollectionEvent(this.createdAt);

  @override
  List<Object> get props => [createdAt];
}

class ClearAllStatsEvent extends HistoryEvent {}

class UpdateStatsCollectionNameEvent extends HistoryEvent {
  final DateTime createdAt;
  final String newName;

  const UpdateStatsCollectionNameEvent({required this.createdAt, required this.newName});

  @override
  List<Object> get props => [createdAt, newName];
}

// ── Export / Import ───────────────────────────────────────────────

class ExportStatsToJsonEvent extends HistoryEvent {
  /// Si es null se exportan todas las colecciones.
  final List<StatsCollection>? collections;

  const ExportStatsToJsonEvent({this.collections});

  @override
  List<Object?> get props => [collections];
}

class ImportStatsFromJsonEvent extends HistoryEvent {
  final String filePath;
  final bool mergeWithExisting;

  const ImportStatsFromJsonEvent({required this.filePath, this.mergeWithExisting = true});

  @override
  List<Object> get props => [filePath, mergeWithExisting];
}
