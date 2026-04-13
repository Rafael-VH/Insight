import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/app_failures.dart';
import 'package:insight/features/history/domain/repositories/history_repository.dart';
import 'package:insight/features/upload/domain/entities/game_session.dart';

class ImportStatsFromJson {
  final HistoryRepository repository;

  ImportStatsFromJson(this.repository);

  Future<Either<Failure, List<StatsCollection>>> call(String filePath) =>
      repository.importStatsFromJson(filePath);
}
