import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';
import 'package:insight/features/stats/domain/repositories/stats_repository.dart';
import 'package:insight/features/stats/domain/usecases/usecase.dart';

class SaveStatsCollection implements UseCase<void, StatsCollection> {
  final StatsRepository repository;

  SaveStatsCollection(this.repository);

  @override
  Future<Either<Failure, void>> call(StatsCollection collection) async {
    return await repository.saveStatsCollection(collection);
  }
}
