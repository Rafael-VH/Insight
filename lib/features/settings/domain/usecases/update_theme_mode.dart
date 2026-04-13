import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/app_failures.dart';
import 'package:insight/features/settings/domain/entities/app_settings.dart';
import 'package:insight/features/settings/domain/repositories/settings_repository.dart';

class UpdateThemeMode {
  final SettingsRepository repository;
  UpdateThemeMode(this.repository);

  Future<Either<Failure, void>> call(AppThemeMode themeMode) async {
    final settingsResult = await repository.getSettings();
    return settingsResult.fold((failure) => Left(failure), (currentSettings) async {
      final updated = currentSettings.copyWith(themeMode: themeMode);
      return await repository.saveSettings(updated);
    });
  }
}
