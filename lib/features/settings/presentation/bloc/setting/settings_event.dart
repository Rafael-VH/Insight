import 'package:equatable/equatable.dart';
import 'package:insight/features/settings/domain/entities/app_settings.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class UpdateThemeMode extends SettingsEvent {
  final AppThemeMode themeMode;

  const UpdateThemeMode(this.themeMode);

  @override
  List<Object> get props => [themeMode];
}

class UpdateSelectedTheme extends SettingsEvent {
  final String themeId;

  const UpdateSelectedTheme(this.themeId);

  @override
  List<Object> get props => [themeId];
}

class UpdateNotifications extends SettingsEvent {
  final bool enabled;

  const UpdateNotifications(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class UpdateHapticFeedback extends SettingsEvent {
  final bool enabled;

  const UpdateHapticFeedback(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class UpdateAutoSave extends SettingsEvent {
  final bool enabled;

  const UpdateAutoSave(this.enabled);

  @override
  List<Object> get props => [enabled];
}

// NUEVO: Evento para cambiar estilo de diálogos
class UpdateAwesomeSnackbar extends SettingsEvent {
  final bool enabled;

  const UpdateAwesomeSnackbar(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class ResetSettings extends SettingsEvent {}
