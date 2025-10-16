import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/stats/data/datasources/settings_datasource.dart';
import 'package:insight/stats/domain/entities/app_settings.dart';

abstract class SettingsRepository {
  Future<Either<Failure, AppSettings>> getSettings();
  Future<Either<Failure, void>> saveSettings(AppSettings settings);
  Future<Either<Failure, void>> resetSettings();
}

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsDataSource dataSource;

  SettingsRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, AppSettings>> getSettings() async {
    try {
      final settings = await dataSource.getSettings();
      return Right(settings);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveSettings(AppSettings settings) async {
    try {
      await dataSource.saveSettings(settings);
      return const Right(null);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> resetSettings() async {
    try {
      await dataSource.resetSettings();
      return const Right(null);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
