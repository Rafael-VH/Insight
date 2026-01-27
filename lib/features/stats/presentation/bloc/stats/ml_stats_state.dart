import 'package:equatable/equatable.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';

abstract class MLStatsState extends Equatable {
  const MLStatsState();

  @override
  List<Object?> get props => [];
}

class MLStatsInitial extends MLStatsState {}

class MLStatsLoading extends MLStatsState {}

class MLStatsSaving extends MLStatsState {
  final String message;
  const MLStatsSaving(this.message);

  @override
  List<Object> get props => [message];
}

class MLStatsSaved extends MLStatsState {
  final String message;

  const MLStatsSaved(this.message);

  @override
  List<Object> get props => [message];
}

class MLStatsCollectionsLoaded extends MLStatsState {
  final List<StatsCollection> collections;

  const MLStatsCollectionsLoaded(this.collections);

  @override
  List<Object> get props => [collections];
}

class MLLatestStatsLoaded extends MLStatsState {
  final StatsCollection? collection;

  const MLLatestStatsLoaded(this.collection);

  @override
  List<Object?> get props => [collection];
}

class MLStatsError extends MLStatsState {
  final String message;
  final String? errorDetails;

  const MLStatsError(this.message, {this.errorDetails});

  @override
  List<Object?> get props => [message, errorDetails];
}

class MLStatsDeleted extends MLStatsState {
  final String message;

  const MLStatsDeleted(this.message);

  @override
  List<Object> get props => [message];
}

class MLStatsCleared extends MLStatsState {
  final String message;

  const MLStatsCleared(this.message);

  @override
  List<Object> get props => [message];
}

// ==================== NUEVOS ESTADOS ====================

class MLStatsNameUpdated extends MLStatsState {
  final String message;
  final String newName;

  const MLStatsNameUpdated({required this.message, required this.newName});

  @override
  List<Object> get props => [message, newName];
}

class MLStatsCollectionByDateLoaded extends MLStatsState {
  final StatsCollection? collection;

  const MLStatsCollectionByDateLoaded(this.collection);

  @override
  List<Object?> get props => [collection];
}
