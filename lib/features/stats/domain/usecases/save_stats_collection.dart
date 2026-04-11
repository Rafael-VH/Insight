import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/history/domain/repositories/history_repository.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';

/// Caso de uso para guardar una nueva [StatsCollection] generada
/// por el flujo de OCR.
///
/// Delega la persistencia a [HistoryRepository], que es el repositorio
/// canónico para todas las operaciones sobre el historial.
class SaveStatsCollection {
  final HistoryRepository repository;

  SaveStatsCollection(this.repository);

  Future<Either<Failure, void>> call(StatsCollection collection) =>
      repository.saveStatsCollection(collection);
}
