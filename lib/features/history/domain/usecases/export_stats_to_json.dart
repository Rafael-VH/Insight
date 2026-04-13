import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/app_failures.dart';
import 'package:insight/features/history/domain/repositories/history_repository.dart';
import 'package:insight/features/upload/domain/entities/game_session.dart';

class ExportStatsToJson {
  final HistoryRepository repository;

  ExportStatsToJson(this.repository);

  Future<Either<Failure, String>> call(List<StatsCollection> collections) =>
      repository.exportStatsToJson(collections);
}
