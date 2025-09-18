import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/stats/domain/entities/stats_collection.dart';
import 'package:insight/stats/domain/repositories/stats_repository.dart';
import 'package:insight/stats/domain/usecases/usecase.dart';

class GetLatestStatsCollection implements UseCase<StatsCollection?, NoParams> {
  final StatsRepository repository;

  GetLatestStatsCollection(this.repository);

  @override
  Future<Either<Failure, StatsCollection?>> call(NoParams params) async {
    return await repository.getLatestStatsCollection();
  }
}
