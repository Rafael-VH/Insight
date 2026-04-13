import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/app_failures.dart';
import 'package:insight/features/history/domain/repositories/history_repository.dart';
import 'package:insight/features/upload/domain/entities/game_session.dart';

class GetLatestStatsCollection {
  final HistoryRepository repository;

  GetLatestStatsCollection(this.repository);

  Future<Either<Failure, StatsCollection?>> call() => repository.getLatestStatsCollection();
}
