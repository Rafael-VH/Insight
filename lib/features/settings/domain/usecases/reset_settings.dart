import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/app_failures.dart';
import 'package:insight/features/settings/domain/repositories/settings_repository.dart';

class ResetSettings {
  final SettingsRepository repository;
  ResetSettings(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.resetSettings();
  }
}
