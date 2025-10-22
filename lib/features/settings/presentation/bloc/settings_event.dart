// ========================================
// EVENTS
// ========================================

import 'package:equatable/equatable.dart';
import 'package:insight/features/settings/domain/entities/app_settings.dart';

/// Eventos base para el manejo de configuración
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Evento: Cargar configuración inicial
class LoadSettings extends SettingsEvent {
  const LoadSettings();

  @override
  String toString() => 'LoadSettings()';
}

/// Evento: Actualizar modo de tema (claro/oscuro/sistema)
class UpdateThemeModeEvent extends SettingsEvent {
  final AppThemeMode themeMode;

  const UpdateThemeModeEvent(this.themeMode);

  @override
  List<Object> get props => [themeMode];

  @override
  String toString() => 'UpdateThemeModeEvent(themeMode: ${themeMode.name})';
}

/// Evento: Actualizar tema seleccionado (ID)
class UpdateSelectedThemeEvent extends SettingsEvent {
  final String themeId;

  const UpdateSelectedThemeEvent(this.themeId);

  @override
  List<Object> get props => [themeId];

  @override
  String toString() => 'UpdateSelectedThemeEvent(themeId: $themeId)';
}

/// Evento: Habilitar/Deshabilitar notificaciones
class UpdateNotificationsEvent extends SettingsEvent {
  final bool enabled;

  const UpdateNotificationsEvent(this.enabled);

  @override
  List<Object> get props => [enabled];

  @override
  String toString() => 'UpdateNotificationsEvent(enabled: $enabled)';
}

/// Evento: Habilitar/Deshabilitar feedback háptico
class UpdateHapticFeedbackEvent extends SettingsEvent {
  final bool enabled;

  const UpdateHapticFeedbackEvent(this.enabled);

  @override
  List<Object> get props => [enabled];

  @override
  String toString() => 'UpdateHapticFeedbackEvent(enabled: $enabled)';
}

/// Evento: Habilitar/Deshabilitar auto-guardado
class UpdateAutoSaveEvent extends SettingsEvent {
  final bool enabled;

  const UpdateAutoSaveEvent(this.enabled);

  @override
  List<Object> get props => [enabled];

  @override
  String toString() => 'UpdateAutoSaveEvent(enabled: $enabled)';
}

/// Evento: Habilitar/Deshabilitar Awesome Snackbar
class UpdateAwesomeSnackbarEvent extends SettingsEvent {
  final bool enabled;

  const UpdateAwesomeSnackbarEvent(this.enabled);

  @override
  List<Object> get props => [enabled];

  @override
  String toString() => 'UpdateAwesomeSnackbarEvent(enabled: $enabled)';
}

/// Evento: Restablecer configuración a valores por defecto
class ResetSettingsEvent extends SettingsEvent {
  const ResetSettingsEvent();

  @override
  String toString() => 'ResetSettingsEvent()';
}
