import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';
import 'package:insight/features/stats/domain/repositories/stats_repository.dart';

class ImportStatsFromJson {
  final StatsRepository repository;
  ImportStatsFromJson(this.repository);

  Future<Either<Failure, List<StatsCollection>>> call(String filePath) async {
    return repository.importStatsFromJson(filePath);
  }
}
