import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';
import 'package:insight/features/stats/domain/repositories/stats_repository.dart';

class ExportStatsToJson {
  final StatsRepository repository;
  ExportStatsToJson(this.repository);

  Future<Either<Failure, String>> call(
    List<StatsCollection> collections,
  ) async {
    return repository.exportStatsToJson(collections);
  }
}
