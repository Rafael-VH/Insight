import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/settings/domain/entities/app_settings.dart';

/// Contrato abstracto del repositorio de configuración
///
/// Define las operaciones que deben ser implementadas por el repositorio concreto
/// en la capa de datos
abstract class SettingsRepository {
  /// Obtiene la configuración actual de la aplicación
  Future<Either<Failure, AppSettings>> getSettings();

  /// Guarda la configuración proporcionada
  Future<Either<Failure, void>> saveSettings(AppSettings settings);

  /// Restablece la configuración a los valores por defecto
  Future<Either<Failure, void>> resetSettings();
}
