import 'package:dartz/dartz.dart';
import 'package:insight/core/errors/failures.dart';
import 'package:insight/features/settings/domain/entities/app_settings.dart';
import 'package:insight/features/settings/domain/repositories/settings_repository.dart';
import 'package:insight/features/stats/domain/usecases/usecase.dart';

/// Caso de uso para obtener la configuración de la aplicación
class SaveSettings implements UseCase<AppSettings, NoParams> {
  final SettingsRepository repository;

  SaveSettings(this.repository);

  @override
  Future<Either<Failure, AppSettings>> call(NoParams params) async {
    return await repository.getSettings();
  }
}
