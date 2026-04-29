import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/app_failures.dart';
import 'package:insight/features/settings/domain/entities/app_theme.dart';

/// Repositorio para gestionar temas personalizados
abstract class AppThemeRepository {
  /// Obtiene todos los temas disponibles (predefinidos + personalizados)
  Future<Either<Failure, List<AppTheme>>> getAllThemes();

  /// Obtiene un tema específico por ID
  Future<Either<Failure, AppTheme?>> getThemeById(String id);

  /// Guarda un tema personalizado
  Future<Either<Failure, void>> saveCustomTheme(AppTheme theme);

  /// Elimina un tema personalizado
  Future<Either<Failure, void>> deleteCustomTheme(String id);

  /// Obtiene todos los temas personalizados
  Future<Either<Failure, List<AppTheme>>> getCustomThemes();
}
