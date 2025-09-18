// lib/features/ml_stats/domain/usecases/get_all_stats_collections.dart
import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/stats/domain/entities/stats_collection.dart';
import 'package:insight/stats/domain/repositories/stats_repository.dart';
import 'package:insight/stats/domain/usecases/usecase.dart';

class GetAllStatsCollections
    implements UseCase<List<StatsCollection>, NoParams> {
  final StatsRepository repository;

  GetAllStatsCollections(this.repository);

  @override
  Future<Either<Failure, List<StatsCollection>>> call(NoParams params) async {
    return await repository.getAllStatsCollections();
  }
}
