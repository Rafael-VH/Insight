import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
//
import 'package:insight/stats/data/repositories/settings_repository.dart';
//
import 'package:insight/stats/domain/entities/app_settings.dart';

// Events
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

class ResetSettings extends SettingsEvent {}

// States
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final AppSettings settings;

  const SettingsLoaded(this.settings);

  @override
  List<Object> get props => [settings];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository repository;
  AppSettings _currentSettings = const AppSettings();

  SettingsBloc({required this.repository}) : super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<UpdateSelectedTheme>(_onUpdateSelectedTheme);
    on<UpdateNotifications>(_onUpdateNotifications);
    on<UpdateHapticFeedback>(_onUpdateHapticFeedback);
    on<UpdateAutoSave>(_onUpdateAutoSave);
    on<ResetSettings>(_onResetSettings);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());

    final result = await repository.getSettings();

    result.fold((failure) => emit(SettingsError(failure.message)), (settings) {
      _currentSettings = settings;
      emit(SettingsLoaded(settings));
    });
  }

  Future<void> _onUpdateThemeMode(
    UpdateThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    final updatedSettings = _currentSettings.copyWith(
      themeMode: event.themeMode,
    );
    await _saveAndEmit(updatedSettings, emit);
  }

  Future<void> _onUpdateSelectedTheme(
    UpdateSelectedTheme event,
    Emitter<SettingsState> emit,
  ) async {
    final updatedSettings = _currentSettings.copyWith(
      selectedThemeId: event.themeId,
    );
    await _saveAndEmit(updatedSettings, emit);
  }

  Future<void> _onUpdateNotifications(
    UpdateNotifications event,
    Emitter<SettingsState> emit,
  ) async {
    final updatedSettings = _currentSettings.copyWith(
      enableNotifications: event.enabled,
    );
    await _saveAndEmit(updatedSettings, emit);
  }

  Future<void> _onUpdateHapticFeedback(
    UpdateHapticFeedback event,
    Emitter<SettingsState> emit,
  ) async {
    final updatedSettings = _currentSettings.copyWith(
      enableHapticFeedback: event.enabled,
    );
    await _saveAndEmit(updatedSettings, emit);
  }

  Future<void> _onUpdateAutoSave(
    UpdateAutoSave event,
    Emitter<SettingsState> emit,
  ) async {
    final updatedSettings = _currentSettings.copyWith(
      autoSaveStats: event.enabled,
    );
    await _saveAndEmit(updatedSettings, emit);
  }

  Future<void> _onResetSettings(
    ResetSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final result = await repository.resetSettings();

    result.fold((failure) => emit(SettingsError(failure.message)), (_) {
      _currentSettings = const AppSettings();
      emit(SettingsLoaded(_currentSettings));
    });
  }

  Future<void> _saveAndEmit(
    AppSettings settings,
    Emitter<SettingsState> emit,
  ) async {
    final result = await repository.saveSettings(settings);

    result.fold((failure) => emit(SettingsError(failure.message)), (_) {
      _currentSettings = settings;
      emit(SettingsLoaded(settings));
    });
  }
}
