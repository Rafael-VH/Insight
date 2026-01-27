import 'package:dartz/dartz.dart';

import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/settings/data/datasources/settings_datasource.dart';
import 'package:insight/features/settings/domain/entities/app_settings.dart';
import 'package:insight/features/settings/domain/repositories/settings_repository.dart';

/// Implementación concreta del repositorio de configuración
///
/// Orquesta las operaciones entre el DataSource y la capa de dominio,
/// manejando errores y transformando excepciones en Failures
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
      return Left(
        FileSystemFailure(
          'Error inesperado al cargar configuración: ${e.toString()}',
        ),
      );
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
      return Left(
        FileSystemFailure(
          'Error inesperado al guardar configuración: ${e.toString()}',
        ),
      );
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
      return Left(
        FileSystemFailure(
          'Error inesperado al restablecer configuración: ${e.toString()}',
        ),
      );
    }
  }
}
