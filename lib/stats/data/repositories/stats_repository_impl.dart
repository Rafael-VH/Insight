import 'package:dartz/dartz.dart';
//
import 'package:insight/core/errors/failures.dart';
//
import 'package:insight/stats/data/datasources/local_storage_datasource.dart';
//
import 'package:insight/stats/domain/entities/stats_collection.dart';
import 'package:insight/stats/domain/repositories/stats_repository.dart';

class StatsRepositoryImpl implements StatsRepository {
  final LocalStorageDataSource localDataSource;

  StatsRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, void>> saveStatsCollection(
    StatsCollection collection,
  ) async {
    try {
      await localDataSource.saveStatsCollection(collection);
      return const Right(null);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<StatsCollection>>>
  getAllStatsCollections() async {
    try {
      final collections = await localDataSource.getAllStatsCollections();
      return Right(collections);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, StatsCollection?>> getLatestStatsCollection() async {
    try {
      final collection = await localDataSource.getLatestStatsCollection();
      return Right(collection);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteStatsCollection(
    DateTime createdAt,
  ) async {
    try {
      await localDataSource.deleteStatsCollection(createdAt);
      return const Right(null);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllStats() async {
    try {
      await localDataSource.clearAllStats();
      return const Right(null);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Unexpected error: ${e.toString()}'));
    }
  }

  // ==================== NUEVOS MÉTODOS ====================

  @override
  Future<Either<Failure, void>> updateStatsCollectionName(
    DateTime createdAt,
    String newName,
  ) async {
    try {
      await localDataSource.updateStatsCollectionName(createdAt, newName);
      return const Right(null);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, StatsCollection?>> getStatsCollectionByDate(
    DateTime createdAt,
  ) async {
    try {
      final collection = await localDataSource.getStatsCollectionByDate(
        createdAt,
      );
      return Right(collection);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
