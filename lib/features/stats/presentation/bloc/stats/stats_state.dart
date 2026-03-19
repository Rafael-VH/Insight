import 'package:equatable/equatable.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';

abstract class StatsState extends Equatable {
  const StatsState();

  @override
  List<Object?> get props => [];
}

class StatsInitial extends StatsState {}

class StatsLoading extends StatsState {}

class StatsSaving extends StatsState {
  final String message;
  const StatsSaving(this.message);

  @override
  List<Object> get props => [message];
}

class StatsSaved extends StatsState {
  final String message;

  const StatsSaved(this.message);

  @override
  List<Object> get props => [message];
}

class StatsCollectionsLoaded extends StatsState {
  final List<StatsCollection> collections;

  const StatsCollectionsLoaded(this.collections);

  @override
  List<Object> get props => [collections];
}

class LatestStatsLoaded extends StatsState {
  final StatsCollection? collection;

  const LatestStatsLoaded(this.collection);

  @override
  List<Object?> get props => [collection];
}

class StatsError extends StatsState {
  final String message;
  final String? errorDetails;

  const StatsError(this.message, {this.errorDetails});

  @override
  List<Object?> get props => [message, errorDetails];
}

class StatsDeleted extends StatsState {
  final String message;

  const StatsDeleted(this.message);

  @override
  List<Object> get props => [message];
}

class StatsCleared extends StatsState {
  final String message;

  const StatsCleared(this.message);

  @override
  List<Object> get props => [message];
}

class StatsNameUpdated extends StatsState {
  final String message;
  final String newName;

  const StatsNameUpdated({required this.message, required this.newName});

  @override
  List<Object> get props => [message, newName];
}

class StatsCollectionByDateLoaded extends StatsState {
  final StatsCollection? collection;

  const StatsCollectionByDateLoaded(this.collection);

  @override
  List<Object?> get props => [collection];
}

class StatsExporting extends StatsState {
  const StatsExporting();
}

class StatsExported extends StatsState {
  final String filePath;
  final int totalCollections;

  const StatsExported({
    required this.filePath,
    required this.totalCollections,
  });

  @override
  List<Object> get props => [filePath, totalCollections];
}

class StatsImporting extends StatsState {
  const StatsImporting();
}

class StatsImported extends StatsState {
  final int importedCount;
  final int skippedCount;
  final bool merged;

  const StatsImported({
    required this.importedCount,
    this.skippedCount = 0,
    required this.merged,
  });

  @override
  List<Object> get props => [importedCount, skippedCount, merged];
}
