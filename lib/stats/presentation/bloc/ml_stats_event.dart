import 'package:equatable/equatable.dart';
//
import 'package:insight/stats/domain/entities/stats_collection.dart';

abstract class MLStatsEvent extends Equatable {
  const MLStatsEvent();

  @override
  List<Object?> get props => [];
}

class SaveStatsCollectionEvent extends MLStatsEvent {
  final StatsCollection collection;

  const SaveStatsCollectionEvent(this.collection);

  @override
  List<Object> get props => [collection];
}

class LoadAllStatsCollectionsEvent extends MLStatsEvent {}

class LoadLatestStatsCollectionEvent extends MLStatsEvent {}

class DeleteStatsCollectionEvent extends MLStatsEvent {
  final DateTime createdAt;

  const DeleteStatsCollectionEvent(this.createdAt);

  @override
  List<Object> get props => [createdAt];
}

class ClearAllStatsEvent extends MLStatsEvent {}
