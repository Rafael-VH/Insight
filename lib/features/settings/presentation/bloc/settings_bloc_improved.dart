import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/core/errors/failures.dart';
//
import 'package:insight/features/settings/domain/usecases/get_settings.dart';
import 'package:insight/features/settings/domain/usecases/reset_settings.dart';
import 'package:insight/features/settings/domain/usecases/save_settings.dart';
import 'package:insight/features/settings/domain/usecases/update_auto_save.dart';
import 'package:insight/features/settings/domain/usecases/update_awesome_snackbar.dart';
import 'package:insight/features/settings/domain/usecases/update_haptic_feedback.dart';
import 'package:insight/features/settings/domain/usecases/update_notifications.dart';
import 'package:insight/features/settings/domain/usecases/update_selected_theme.dart';
import 'package:insight/features/settings/domain/usecases/update_theme_mode.dart';
//
import 'package:insight/features/settings/presentation/bloc/settings_event.dart';
import 'package:insight/features/settings/presentation/bloc/settings_state.dart';
//
import 'package:insight/features/stats/domain/usecases/usecase.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  // Casos de uso inyectados
  final GetSettings getSettings;
  final SaveSettings saveSettings;
  final ResetSettings resetSettings;
  final UpdateThemeMode updateThemeMode;
  final UpdateSelectedTheme updateSelectedTheme;
  final UpdateNotifications updateNotifications;
  final UpdateHapticFeedback updateHapticFeedback;
  final UpdateAutoSave updateAutoSave;
  final UpdateAwesomeSnackbar updateAwesomeSnackbar;

  SettingsBloc({
    required this.getSettings,
    required this.saveSettings,
    required this.resetSettings,
    required this.updateThemeMode,
    required this.updateSelectedTheme,
    required this.updateNotifications,
    required this.updateHapticFeedback,
    required this.updateAutoSave,
    required this.updateAwesomeSnackbar,
  }) : super(const SettingsInitial()) {
    // Registrar handlers para cada evento
    on<LoadSettings>(_onLoadSettings);
    on<UpdateThemeModeEvent>(_onUpdateThemeMode);
    on<UpdateSelectedThemeEvent>(_onUpdateSelectedTheme);
    on<UpdateNotificationsEvent>(_onUpdateNotifications);
    on<UpdateHapticFeedbackEvent>(_onUpdateHapticFeedback);
    on<UpdateAutoSaveEvent>(_onUpdateAutoSave);
    on<UpdateAwesomeSnackbarEvent>(_onUpdateAwesomeSnackbar);
    on<ResetSettingsEvent>(_onResetSettings);
  }

  // ==================== EVENT HANDLERS ====================

  /// Handler: Cargar configuración inicial
  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    print('🔄 [SettingsBloc] Cargando configuración...');
    emit(const SettingsLoading());

    final result = await getSettings(NoParams());

    result.fold(
      (failure) {
        print('❌ [SettingsBloc] Error al cargar: ${failure.message}');
        emit(
          SettingsError(
            'Error al cargar configuración',
            errorDetails: failure.message,
          ),
        );
      },
      (settings) {
        print('✅ [SettingsBloc] Configuración cargada exitosamente');
        emit(SettingsLoaded(settings));
      },
    );
  }

  /// Handler: Actualizar modo de tema
  Future<void> _onUpdateThemeMode(
    UpdateThemeModeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    print(
      '🎨 [SettingsBloc] Actualizando modo de tema: ${event.themeMode.name}',
    );

    // Obtener configuración actual para mostrarla mientras actualizamos
    final currentState = state;
    if (currentState is SettingsLoaded) {
      emit(
        SettingsUpdating(currentState.settings, 'Actualizando modo de tema...'),
      );
    }

    final params = UpdateThemeModeParams(themeMode: event.themeMode);
    final result = await updateThemeMode(params);

    await result.fold(
      (failure) async {
        print(
          '❌ [SettingsBloc] Error al actualizar modo de tema: ${failure.message}',
        );
        emit(
          SettingsError(
            'Error al actualizar modo de tema',
            errorDetails: failure.message,
          ),
        );
      },
      (_) async {
        print('✅ [SettingsBloc] Modo de tema actualizado');
        // Recargar configuración actualizada
        await _reloadSettings(emit, 'Modo de tema actualizado');
      },
    );
  }

  /// Handler: Actualizar tema seleccionado (ID)
  Future<void> _onUpdateSelectedTheme(
    UpdateSelectedThemeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    print('🎨 [SettingsBloc] Actualizando tema seleccionado: ${event.themeId}');

    final currentState = state;
    if (currentState is SettingsLoaded) {
      emit(SettingsUpdating(currentState.settings, 'Actualizando tema...'));
    }

    final params = UpdateSelectedThemeParams(themeId: event.themeId);
    final result = await updateSelectedTheme(params);

    await result.fold(
      (failure) async {
        print('❌ [SettingsBloc] Error al actualizar tema: ${failure.message}');
        emit(
          SettingsError(
            'Error al actualizar tema',
            errorDetails: failure.message,
          ),
        );
      },
      (_) async {
        print('✅ [SettingsBloc] Tema actualizado');
        await _reloadSettings(emit, 'Tema actualizado');
      },
    );
  }

  /// Handler: Actualizar notificaciones
  Future<void> _onUpdateNotifications(
    UpdateNotificationsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    print('🔔 [SettingsBloc] Actualizando notificaciones: ${event.enabled}');

    final params = UpdateNotificationsParams(enabled: event.enabled);
    final result = await updateNotifications(params);

    await _handleUpdateResult(
      result,
      emit,
      successMessage: event.enabled
          ? 'Notificaciones activadas'
          : 'Notificaciones desactivadas',
      errorMessage: 'Error al actualizar notificaciones',
    );
  }

  /// Handler: Actualizar feedback háptico
  Future<void> _onUpdateHapticFeedback(
    UpdateHapticFeedbackEvent event,
    Emitter<SettingsState> emit,
  ) async {
    print('📳 [SettingsBloc] Actualizando feedback háptico: ${event.enabled}');

    final params = UpdateHapticFeedbackParams(enabled: event.enabled);
    final result = await updateHapticFeedback(params);

    await _handleUpdateResult(
      result,
      emit,
      successMessage: event.enabled
          ? 'Feedback háptico activado'
          : 'Feedback háptico desactivado',
      errorMessage: 'Error al actualizar feedback háptico',
    );
  }

  /// Handler: Actualizar auto-guardado
  Future<void> _onUpdateAutoSave(
    UpdateAutoSaveEvent event,
    Emitter<SettingsState> emit,
  ) async {
    print('💾 [SettingsBloc] Actualizando auto-guardado: ${event.enabled}');

    final params = UpdateAutoSaveParams(enabled: event.enabled);
    final result = await updateAutoSave(params);

    await _handleUpdateResult(
      result,
      emit,
      successMessage: event.enabled
          ? 'Auto-guardado activado'
          : 'Auto-guardado desactivado',
      errorMessage: 'Error al actualizar auto-guardado',
    );
  }

  /// Handler: Actualizar Awesome Snackbar
  Future<void> _onUpdateAwesomeSnackbar(
    UpdateAwesomeSnackbarEvent event,
    Emitter<SettingsState> emit,
  ) async {
    print('🎉 [SettingsBloc] Actualizando Awesome Snackbar: ${event.enabled}');

    final params = UpdateAwesomeSnackbarParams(enabled: event.enabled);
    final result = await updateAwesomeSnackbar(params);

    await _handleUpdateResult(
      result,
      emit,
      successMessage: event.enabled
          ? 'Diálogos mejorados activados'
          : 'Diálogos clásicos activados',
      errorMessage: 'Error al actualizar estilo de diálogos',
    );
  }

  /// Handler: Restablecer configuración
  Future<void> _onResetSettings(
    ResetSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    print('🔄 [SettingsBloc] Restableciendo configuración...');

    emit(const SettingsLoading());

    final result = await resetSettings(NoParams());

    await result.fold(
      (failure) async {
        print('❌ [SettingsBloc] Error al restablecer: ${failure.message}');
        emit(
          SettingsError(
            'Error al restablecer configuración',
            errorDetails: failure.message,
          ),
        );
      },
      (_) async {
        print('✅ [SettingsBloc] Configuración restablecida');
        await _reloadSettings(
          emit,
          'Configuración restablecida a valores por defecto',
        );
      },
    );
  }

  // ==================== MÉTODOS AUXILIARES ====================

  /// Recarga la configuración y emite un estado actualizado
  Future<void> _reloadSettings(
    Emitter<SettingsState> emit,
    String successMessage,
  ) async {
    final result = await getSettings(NoParams());

    result.fold(
      (failure) {
        emit(
          SettingsError(
            'Error al recargar configuración',
            errorDetails: failure.message,
          ),
        );
      },
      (settings) {
        emit(SettingsUpdated(settings, successMessage));
        // Después de un breve tiempo, volver a SettingsLoaded
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!isClosed) {
            emit(SettingsLoaded(settings));
          }
        });
      },
    );
  }

  /// Maneja el resultado de una actualización genérica
  Future<void> _handleUpdateResult(
    Either<Failure, void> result,
    Emitter<SettingsState> emit, {
    required String successMessage,
    required String errorMessage,
  }) async {
    await result.fold(
      (failure) async {
        print('❌ [SettingsBloc] $errorMessage: ${failure.message}');
        emit(SettingsError(errorMessage, errorDetails: failure.message));
      },
      (_) async {
        print('✅ [SettingsBloc] $successMessage');
        await _reloadSettings(emit, successMessage);
      },
    );
  }

  // ==================== DEBUG ====================

  @override
  void onEvent(SettingsEvent event) {
    super.onEvent(event);
    print('📥 [SettingsBloc] Event: $event');
  }

  @override
  void onTransition(Transition<SettingsEvent, SettingsState> transition) {
    super.onTransition(transition);
    print(
      '🔄 [SettingsBloc] Transition: ${transition.currentState.runtimeType} → ${transition.nextState.runtimeType}',
    );
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    print('❌ [SettingsBloc] Error: $error');
    print('Stack trace: $stackTrace');
    super.onError(error, stackTrace);
  }
}
