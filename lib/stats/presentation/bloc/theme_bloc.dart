import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/stats/data/repositories/settings_repository.dart';
import 'package:insight/stats/domain/entities/app_settings.dart';
import 'package:insight/stats/domain/entities/app_theme.dart';
import 'package:insight/stats/domain/repositories/theme_repository.dart';

// ========== EVENTS ==========
abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class LoadTheme extends ThemeEvent {}

class ChangeTheme extends ThemeEvent {
  final String themeId;

  const ChangeTheme(this.themeId);

  @override
  List<Object> get props => [themeId];
}

class ChangeThemeMode extends ThemeEvent {
  final AppThemeMode mode;

  const ChangeThemeMode(this.mode);

  @override
  List<Object> get props => [mode];
}

class LoadAllThemes extends ThemeEvent {}

class SaveCustomTheme extends ThemeEvent {
  final AppTheme theme;

  const SaveCustomTheme(this.theme);

  @override
  List<Object> get props => [theme];
}

class DeleteCustomTheme extends ThemeEvent {
  final String themeId;

  const DeleteCustomTheme(this.themeId);

  @override
  List<Object> get props => [themeId];
}

// ========== STATES ==========
abstract class ThemeState extends Equatable {
  const ThemeState();

  @override
  List<Object?> get props => [];
}

class ThemeInitial extends ThemeState {}

class ThemeLoading extends ThemeState {}

class ThemeLoaded extends ThemeState {
  final AppTheme currentTheme;
  final AppThemeMode themeMode;
  final List<AppTheme> availableThemes;

  const ThemeLoaded({
    required this.currentTheme,
    required this.themeMode,
    required this.availableThemes,
  });

  @override
  List<Object> get props => [currentTheme, themeMode, availableThemes];

  ThemeLoaded copyWith({
    AppTheme? currentTheme,
    AppThemeMode? themeMode,
    List<AppTheme>? availableThemes,
  }) {
    return ThemeLoaded(
      currentTheme: currentTheme ?? this.currentTheme,
      themeMode: themeMode ?? this.themeMode,
      availableThemes: availableThemes ?? this.availableThemes,
    );
  }
}

class ThemeError extends ThemeState {
  final String message;

  const ThemeError(this.message);

  @override
  List<Object> get props => [message];
}

// ========== BLOC ==========
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final SettingsRepository settingsRepository;
  final ThemeRepository themeRepository;

  ThemeBloc({required this.settingsRepository, required this.themeRepository})
    : super(ThemeInitial()) {
    on<LoadTheme>(_onLoadTheme);
    on<ChangeTheme>(_onChangeTheme);
    on<ChangeThemeMode>(_onChangeThemeMode);
    on<LoadAllThemes>(_onLoadAllThemes);
    on<SaveCustomTheme>(_onSaveCustomTheme);
    on<DeleteCustomTheme>(_onDeleteCustomTheme);
  }

  Future<void> _onLoadTheme(LoadTheme event, Emitter<ThemeState> emit) async {
    emit(ThemeLoading());

    try {
      // Cargar configuración
      final settingsResult = await settingsRepository.getSettings();

      await settingsResult.fold(
        (failure) async => emit(ThemeError(failure.message)),
        (settings) async {
          // Cargar tema actual
          final themeResult = await themeRepository.getThemeById(
            settings.selectedThemeId,
          );

          await themeResult.fold(
            (failure) async => emit(ThemeError(failure.message)),
            (theme) async {
              final currentTheme = theme ?? AppThemes.defaultTheme;

              // Cargar todos los temas disponibles
              final allThemesResult = await themeRepository.getAllThemes();

              allThemesResult.fold(
                (failure) => emit(ThemeError(failure.message)),
                (themes) => emit(
                  ThemeLoaded(
                    currentTheme: currentTheme,
                    themeMode: settings.themeMode,
                    availableThemes: themes,
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      emit(ThemeError('Error inesperado: ${e.toString()}'));
    }
  }

  Future<void> _onChangeTheme(
    ChangeTheme event,
    Emitter<ThemeState> emit,
  ) async {
    if (state is! ThemeLoaded) return;

    final currentState = state as ThemeLoaded;

    try {
      // Cargar el nuevo tema
      final themeResult = await themeRepository.getThemeById(event.themeId);

      await themeResult.fold(
        (failure) async => emit(ThemeError(failure.message)),
        (theme) async {
          if (theme == null) {
            emit(const ThemeError('Tema no encontrado'));
            return;
          }

          // Actualizar configuración
          final settingsResult = await settingsRepository.getSettings();

          await settingsResult.fold(
            (failure) async => emit(ThemeError(failure.message)),
            (settings) async {
              final updatedSettings = settings.copyWith(
                selectedThemeId: event.themeId,
              );

              final saveResult = await settingsRepository.saveSettings(
                updatedSettings,
              );

              saveResult.fold(
                (failure) => emit(ThemeError(failure.message)),
                (_) => emit(currentState.copyWith(currentTheme: theme)),
              );
            },
          );
        },
      );
    } catch (e) {
      emit(ThemeError('Error cambiando tema: ${e.toString()}'));
    }
  }

  Future<void> _onChangeThemeMode(
    ChangeThemeMode event,
    Emitter<ThemeState> emit,
  ) async {
    if (state is! ThemeLoaded) return;

    final currentState = state as ThemeLoaded;

    try {
      final settingsResult = await settingsRepository.getSettings();

      await settingsResult.fold(
        (failure) async => emit(ThemeError(failure.message)),
        (settings) async {
          final updatedSettings = settings.copyWith(themeMode: event.mode);

          final saveResult = await settingsRepository.saveSettings(
            updatedSettings,
          );

          saveResult.fold(
            (failure) => emit(ThemeError(failure.message)),
            (_) => emit(currentState.copyWith(themeMode: event.mode)),
          );
        },
      );
    } catch (e) {
      emit(ThemeError('Error cambiando modo: ${e.toString()}'));
    }
  }

  Future<void> _onLoadAllThemes(
    LoadAllThemes event,
    Emitter<ThemeState> emit,
  ) async {
    if (state is! ThemeLoaded) return;

    final currentState = state as ThemeLoaded;

    try {
      final themesResult = await themeRepository.getAllThemes();

      themesResult.fold(
        (failure) => emit(ThemeError(failure.message)),
        (themes) => emit(currentState.copyWith(availableThemes: themes)),
      );
    } catch (e) {
      emit(ThemeError('Error cargando temas: ${e.toString()}'));
    }
  }

  Future<void> _onSaveCustomTheme(
    SaveCustomTheme event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      final saveResult = await themeRepository.saveCustomTheme(event.theme);

      await saveResult.fold(
        (failure) async => emit(ThemeError(failure.message)),
        (_) async {
          // Recargar temas
          add(LoadAllThemes());

          // Cambiar al nuevo tema
          add(ChangeTheme(event.theme.id));
        },
      );
    } catch (e) {
      emit(ThemeError('Error guardando tema: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteCustomTheme(
    DeleteCustomTheme event,
    Emitter<ThemeState> emit,
  ) async {
    if (state is! ThemeLoaded) return;

    final currentState = state as ThemeLoaded;

    try {
      final deleteResult = await themeRepository.deleteCustomTheme(
        event.themeId,
      );

      await deleteResult.fold(
        (failure) async => emit(ThemeError(failure.message)),
        (_) async {
          // Si el tema eliminado es el actual, cambiar al tema por defecto
          if (currentState.currentTheme.id == event.themeId) {
            add(ChangeTheme(AppThemes.defaultTheme.id));
          }

          // Recargar lista de temas
          add(LoadAllThemes());
        },
      );
    } catch (e) {
      emit(ThemeError('Error eliminando tema: ${e.toString()}'));
    }
  }
}
