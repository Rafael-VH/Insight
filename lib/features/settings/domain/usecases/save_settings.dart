import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/app_failures.dart';
import 'package:insight/features/settings/domain/entities/app_settings.dart';
import 'package:insight/features/settings/domain/repositories/settings_repository.dart';

class SaveSettings {
  final SettingsRepository repository;
  SaveSettings(this.repository);

  Future<Either<Failure, void>> call(AppSettings settings) async {
    return await repository.saveSettings(settings);
  }
}
