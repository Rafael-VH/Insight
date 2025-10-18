import 'package:dartz/dartz.dart';
//
import 'package:insight/core/errors/failures.dart';
//
import 'package:insight/stats/domain/entities/stats_collection.dart';

abstract class StatsRepository {
  Future<Either<Failure, void>> saveStatsCollection(StatsCollection collection);
  Future<Either<Failure, List<StatsCollection>>> getAllStatsCollections();
  Future<Either<Failure, StatsCollection?>> getLatestStatsCollection();
  Future<Either<Failure, void>> deleteStatsCollection(DateTime createdAt);
  Future<Either<Failure, void>> clearAllStats();
}
