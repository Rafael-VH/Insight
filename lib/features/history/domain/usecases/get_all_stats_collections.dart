import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/history/domain/repositories/history_repository.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';

class GetAllStatsCollections {
  final HistoryRepository repository;

  GetAllStatsCollections(this.repository);

  Future<Either<Failure, List<StatsCollection>>> call() =>
      repository.getAllStatsCollections();
}
