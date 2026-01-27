import 'package:equatable/equatable.dart';
import 'package:insight/features/settings/domain/entities/app_settings.dart';
import 'package:insight/features/settings/domain/entities/app_theme.dart';

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
