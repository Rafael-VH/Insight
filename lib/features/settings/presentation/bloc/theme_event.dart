import 'package:equatable/equatable.dart';
import 'package:insight/features/settings/domain/entities/app_settings.dart';
import 'package:insight/features/settings/domain/entities/app_theme.dart';

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
