// lib/features/ml_stats/presentation/bloc/ml_stats_state.dart
import 'package:equatable/equatable.dart';
import 'package:insight/stats/domain/entities/stats_collection.dart';

abstract class MLStatsState extends Equatable {
  const MLStatsState();

  @override
  List<Object?> get props => [];
}

class MLStatsInitial extends MLStatsState {}

class MLStatsLoading extends MLStatsState {}

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

  const MLStatsError(this.message);

  @override
  List<Object> get props => [message];
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
