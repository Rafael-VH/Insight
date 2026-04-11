import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/history/domain/repositories/history_repository.dart';

class UpdateStatsCollectionName {
  final HistoryRepository repository;

  UpdateStatsCollectionName(this.repository);

  Future<Either<Failure, void>> call(UpdateNameParams params) {
    if (params.newName.isEmpty) {
      return Future.value(const Left(FileSystemFailure('El nombre no puede estar vacío')));
    }
    if (params.newName.length > 50) {
      return Future.value(
        const Left(FileSystemFailure('El nombre no puede exceder 50 caracteres')),
      );
    }
    return repository.updateStatsCollectionName(params.createdAt, params.newName);
  }
}

class UpdateNameParams {
  final DateTime createdAt;
  final String newName;

  const UpdateNameParams({required this.createdAt, required this.newName});
}
