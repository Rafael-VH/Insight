import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/app_failures.dart';
import 'package:insight/features/history/domain/repositories/history_repository.dart';
import 'package:insight/features/upload/domain/entities/game_session.dart';

class SaveCollectionsBatch {
  final HistoryRepository repository;

  SaveCollectionsBatch(this.repository);

  Future<Either<Failure, int>> call(
    List<StatsCollection> collections, {
    bool replaceExisting = false,
  }) => repository.saveCollectionsBatch(collections, replaceExisting: replaceExisting);
}
