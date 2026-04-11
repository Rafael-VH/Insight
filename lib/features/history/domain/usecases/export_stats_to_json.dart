import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/history/domain/repositories/history_repository.dart';
import 'package:insight/features/upload/domain/entities/stats_collection.dart';

class ExportStatsToJson {
  final HistoryRepository repository;

  ExportStatsToJson(this.repository);

  Future<Either<Failure, String>> call(List<StatsCollection> collections) =>
      repository.exportStatsToJson(collections);
}
