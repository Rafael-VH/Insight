import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/settings/domain/entities/app_settings.dart';
import 'package:insight/features/settings/domain/repositories/settings_repository.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_event.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_state.dart';

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
    on<UpdateAwesomeSnackbar>(_onUpdateAwesomeSnackbar); // NUEVO
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

  // NUEVO: Manejador para cambiar estilo de diálogos
  Future<void> _onUpdateAwesomeSnackbar(
    UpdateAwesomeSnackbar event,
    Emitter<SettingsState> emit,
  ) async {
    final updatedSettings = _currentSettings.copyWith(
      useAwesomeSnackbar: event.enabled,
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
