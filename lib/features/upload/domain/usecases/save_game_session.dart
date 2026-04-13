import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/app_failures.dart';
import 'package:insight/features/history/domain/repositories/history_repository.dart';
import 'package:insight/features/upload/domain/entities/game_session.dart';

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
