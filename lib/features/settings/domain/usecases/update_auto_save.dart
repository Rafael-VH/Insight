import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/settings/domain/repositories/settings_repository.dart';

/// Caso de uso para habilitar/deshabilitar auto-guardado de estadísticas
///
/// Cuando está habilitado, las estadísticas se guardan automáticamente
/// después de ser procesadas por OCR
class UpdateAutoSave {
  final SettingsRepository repository;

  UpdateAutoSave(this.repository);

  Future<Either<Failure, void>> call(UpdateAutoSaveParams params) async {
    // Obtener configuración actual
    final settingsResult = await repository.getSettings();

    return settingsResult.fold((failure) => Left(failure), (
      currentSettings,
    ) async {
      // Actualizar solo el auto-guardado
      final updatedSettings = currentSettings.copyWith(
        autoSaveStats: params.enabled,
      );

      // Guardar la configuración actualizada
      return await repository.saveSettings(updatedSettings);
    });
  }
}

/// Parámetros para actualizar auto-guardado
class UpdateAutoSaveParams {
  final bool enabled;

  const UpdateAutoSaveParams({required this.enabled});
}
