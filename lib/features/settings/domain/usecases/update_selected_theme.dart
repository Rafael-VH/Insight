import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/settings/domain/repositories/settings_repository.dart';

/// Caso de uso para actualizar el tema seleccionado (ID del tema)
///
/// Este caso de uso obtiene la configuración actual, actualiza solo el ID del tema,
/// y guarda los cambios.
class UpdateSelectedTheme {
  final SettingsRepository repository;

  UpdateSelectedTheme(this.repository);

  Future<Either<Failure, void>> call(UpdateSelectedThemeParams params) async {
    // Validación del ID del tema
    if (params.themeId.isEmpty) {
      return const Left(
        FileSystemFailure('El ID del tema no puede estar vacío'),
      );
    }

    // Obtener configuración actual
    final settingsResult = await repository.getSettings();

    return settingsResult.fold((failure) => Left(failure), (
      currentSettings,
    ) async {
      // Actualizar solo el tema seleccionado
      final updatedSettings = currentSettings.copyWith(
        selectedThemeId: params.themeId,
      );

      // Guardar la configuración actualizada
      return await repository.saveSettings(updatedSettings);
    });
  }
}

/// Parámetros para actualizar el tema seleccionado
class UpdateSelectedThemeParams {
  final String themeId;

  const UpdateSelectedThemeParams({required this.themeId});
}
