import 'package:dartz/dartz.dart';
//
import 'package:insight/core/errors/failures.dart';
//
import 'package:insight/features/stats/data/datasources/theme_datasource.dart';
//
import 'package:insight/features/stats/domain/entities/app_theme.dart';
import 'package:insight/features/stats/domain/repositories/theme_repository.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  final ThemeDataSource dataSource;

  ThemeRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<AppTheme>>> getAllThemes() async {
    try {
      final themes = await dataSource.getAllThemes();
      return Right(themes);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AppTheme?>> getThemeById(String id) async {
    try {
      final theme = await dataSource.getThemeById(id);
      return Right(theme);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveCustomTheme(AppTheme theme) async {
    try {
      if (!theme.isCustom) {
        return const Left(
          FileSystemFailure('Cannot save predefined theme as custom'),
        );
      }
      await dataSource.saveCustomTheme(theme);
      return const Right(null);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomTheme(String id) async {
    try {
      await dataSource.deleteCustomTheme(id);
      return const Right(null);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<AppTheme>>> getCustomThemes() async {
    try {
      final themes = await dataSource.getCustomThemes();
      return Right(themes);
    } on FileSystemFailure catch (e) {
      return Left(FileSystemFailure(e.message));
    } catch (e) {
      return Left(FileSystemFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
