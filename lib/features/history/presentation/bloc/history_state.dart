import 'package:equatable/equatable.dart';
import 'package:insight/features/upload/domain/entities/game_session.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

// ── Estados generales ─────────────────────────────────────────────

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryError extends HistoryState {
  final String message;
  final String? errorDetails;

  const HistoryError(this.message, {this.errorDetails});

  @override
  List<Object?> get props => [message, errorDetails];
}

// ── Estados de carga ──────────────────────────────────────────────

class HistoryCollectionsLoaded extends HistoryState {
  final List<StatsCollection> collections;

  const HistoryCollectionsLoaded(this.collections);

  @override
  List<Object> get props => [collections];
}

class HistoryLatestLoaded extends HistoryState {
  final StatsCollection? collection;

  const HistoryLatestLoaded(this.collection);

  @override
  List<Object?> get props => [collection];
}

class HistoryCollectionByDateLoaded extends HistoryState {
  final StatsCollection? collection;

  const HistoryCollectionByDateLoaded(this.collection);

  @override
  List<Object?> get props => [collection];
}

// ── Estados de mutación ───────────────────────────────────────────

class HistoryDeleted extends HistoryState {
  final String message;

  const HistoryDeleted(this.message);

  @override
  List<Object> get props => [message];
}

class HistoryCleared extends HistoryState {
  final String message;

  const HistoryCleared(this.message);

  @override
  List<Object> get props => [message];
}

class HistoryNameUpdated extends HistoryState {
  final String message;
  final String newName;

  const HistoryNameUpdated({required this.message, required this.newName});

  @override
  List<Object> get props => [message, newName];
}

// ── Estados de export / import ────────────────────────────────────

class HistoryExporting extends HistoryState {
  const HistoryExporting();
}

class HistoryExported extends HistoryState {
  final String filePath;
  final int totalCollections;

  const HistoryExported({required this.filePath, required this.totalCollections});

  @override
  List<Object> get props => [filePath, totalCollections];
}

class HistoryImporting extends HistoryState {
  const HistoryImporting();
}

class HistoryImported extends HistoryState {
  final int importedCount;
  final int skippedCount;
  final bool merged;

  const HistoryImported({required this.importedCount, this.skippedCount = 0, required this.merged});

  @override
  List<Object> get props => [importedCount, skippedCount, merged];
}
