import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/settings/domain/repositories/settings_repository.dart';

/// Caso de uso para habilitar/deshabilitar estilo Awesome Snackbar
///
/// Cuando está habilitado, se usan notificaciones estilo "Awesome Snackbar"
/// en lugar de los diálogos clásicos de Material Design
class UpdateAwesomeSnackbar {
  final SettingsRepository repository;

  UpdateAwesomeSnackbar(this.repository);

  Future<Either<Failure, void>> call(UpdateAwesomeSnackbarParams params) async {
    // Obtener configuración actual
    final settingsResult = await repository.getSettings();

    return settingsResult.fold((failure) => Left(failure), (
      currentSettings,
    ) async {
      // Actualizar solo el estilo de snackbar
      final updatedSettings = currentSettings.copyWith(
        useAwesomeSnackbar: params.enabled,
      );

      // Guardar la configuración actualizada
      return await repository.saveSettings(updatedSettings);
    });
  }
}

/// Parámetros para actualizar estilo de Snackbar
class UpdateAwesomeSnackbarParams {
  final bool enabled;

  const UpdateAwesomeSnackbarParams({required this.enabled});
}
