import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/settings/domain/repositories/settings_repository.dart';

/// Caso de uso para habilitar/deshabilitar notificaciones
class UpdateNotifications {
  final SettingsRepository repository;

  UpdateNotifications(this.repository);

  Future<Either<Failure, void>> call(UpdateNotificationsParams params) async {
    // Obtener configuración actual
    final settingsResult = await repository.getSettings();

    return settingsResult.fold((failure) => Left(failure), (
      currentSettings,
    ) async {
      // Actualizar solo las notificaciones
      final updatedSettings = currentSettings.copyWith(
        enableNotifications: params.enabled,
      );

      // Guardar la configuración actualizada
      return await repository.saveSettings(updatedSettings);
    });
  }
}

/// Parámetros para actualizar notificaciones
class UpdateNotificationsParams {
  final bool enabled;

  const UpdateNotificationsParams({required this.enabled});
}
