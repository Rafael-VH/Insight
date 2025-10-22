import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/settings/domain/repositories/settings_repository.dart';

/// Caso de uso para habilitar/deshabilitar feedback háptico
///
/// El feedback háptico proporciona vibraciones suaves al interactuar con la UI
class UpdateHapticFeedback {
  final SettingsRepository repository;

  UpdateHapticFeedback(this.repository);

  Future<Either<Failure, void>> call(UpdateHapticFeedbackParams params) async {
    // Obtener configuración actual
    final settingsResult = await repository.getSettings();

    return settingsResult.fold((failure) => Left(failure), (
      currentSettings,
    ) async {
      // Actualizar solo el feedback háptico
      final updatedSettings = currentSettings.copyWith(
        enableHapticFeedback: params.enabled,
      );

      // Guardar la configuración actualizada
      return await repository.saveSettings(updatedSettings);
    });
  }
}

/// Parámetros para actualizar feedback háptico
class UpdateHapticFeedbackParams {
  final bool enabled;

  const UpdateHapticFeedbackParams({required this.enabled});
}
