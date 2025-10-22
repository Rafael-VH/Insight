import 'package:equatable/equatable.dart';
import 'package:insight/features/settings/domain/entities/app_settings.dart';

/// Estados base para la configuración
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

/// Estado: Configuración inicial (sin cargar)
class SettingsInitial extends SettingsState {
  const SettingsInitial();

  @override
  String toString() => 'SettingsInitial()';
}

/// Estado: Cargando configuración
class SettingsLoading extends SettingsState {
  const SettingsLoading();

  @override
  String toString() => 'SettingsLoading()';
}

/// Estado: Configuración cargada exitosamente
class SettingsLoaded extends SettingsState {
  final AppSettings settings;

  const SettingsLoaded(this.settings);

  @override
  List<Object> get props => [settings];

  @override
  String toString() => 'SettingsLoaded(settings: $settings)';
}

/// Estado: Actualizando configuración (para mostrar indicador)
class SettingsUpdating extends SettingsState {
  final AppSettings currentSettings;
  final String updateMessage;

  const SettingsUpdating(this.currentSettings, this.updateMessage);

  @override
  List<Object> get props => [currentSettings, updateMessage];

  @override
  String toString() =>
      'SettingsUpdating(message: $updateMessage, settings: $currentSettings)';
}

/// Estado: Configuración actualizada exitosamente
class SettingsUpdated extends SettingsState {
  final AppSettings settings;
  final String successMessage;

  const SettingsUpdated(this.settings, this.successMessage);

  @override
  List<Object> get props => [settings, successMessage];

  @override
  String toString() =>
      'SettingsUpdated(message: $successMessage, settings: $settings)';
}

/// Estado: Error al cargar/actualizar configuración
class SettingsError extends SettingsState {
  final String message;
  final String? errorDetails;

  const SettingsError(this.message, {this.errorDetails});

  @override
  List<Object?> get props => [message, errorDetails];

  @override
  String toString() =>
      'SettingsError(message: $message, details: $errorDetails)';
}
