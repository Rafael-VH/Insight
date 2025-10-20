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

// ==================== NUEVOS EVENTOS ====================

class UpdateStatsCollectionNameEvent extends MLStatsEvent {
  final DateTime createdAt;
  final String newName;

  const UpdateStatsCollectionNameEvent({
    required this.createdAt,
    required this.newName,
  });

  @override
  List<Object> get props => [createdAt, newName];
}

class GetStatsCollectionByDateEvent extends MLStatsEvent {
  final DateTime createdAt;

  const GetStatsCollectionByDateEvent(this.createdAt);

  @override
  List<Object> get props => [createdAt];
}
