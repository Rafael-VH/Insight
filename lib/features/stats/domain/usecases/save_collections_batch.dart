import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';
import 'package:insight/features/stats/domain/repositories/stats_repository.dart';

class SaveCollectionsBatch {
  final StatsRepository repository;
  SaveCollectionsBatch(this.repository);

  Future<Either<Failure, int>> call(
    List<StatsCollection> collections, {
    bool replaceExisting = false,
  }) async {
    return repository.saveCollectionsBatch(
      collections,
      replaceExisting: replaceExisting,
    );
  }
}
