import 'package:dartz/dartz.dart';
//
import 'package:insight/core/errors/failures.dart';
//
import 'package:insight/stats/domain/repositories/stats_repository.dart';

class UpdateStatsCollectionName {
  final StatsRepository repository;

  UpdateStatsCollectionName(this.repository);

  Future<Either<Failure, void>> call(UpdateNameParams params) async {
    if (params.newName.isEmpty) {
      return const Left(FileSystemFailure('El nombre no puede estar vacío'));
    }

    if (params.newName.length > 50) {
      return const Left(
        FileSystemFailure('El nombre no puede exceder 50 caracteres'),
      );
    }

    return await repository.updateStatsCollectionName(
      params.createdAt,
      params.newName,
    );
  }
}

class UpdateNameParams {
  final DateTime createdAt;
  final String newName;

  const UpdateNameParams({required this.createdAt, required this.newName});
}
