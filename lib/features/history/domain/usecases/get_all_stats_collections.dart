import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/app_failures.dart';
import 'package:insight/features/history/domain/repositories/history_repository.dart';
import 'package:insight/features/upload/domain/entities/game_session.dart';

class GetAllStatsCollections {
  final HistoryRepository repository;

  GetAllStatsCollections(this.repository);

  Future<Either<Failure, List<StatsCollection>>> call() => repository.getAllStatsCollections();
}
