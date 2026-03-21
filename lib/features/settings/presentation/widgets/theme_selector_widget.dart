import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/settings/domain/entities/app_theme.dart';
import 'package:insight/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:insight/features/settings/presentation/bloc/theme/theme_state.dart';
import 'package:insight/features/settings/presentation/screens/widgets/create_custom_theme_bottom_sheet.dart';

class ThemeSelectorWidget extends StatelessWidget {
  const ThemeSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        if (state is! ThemeLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Temas Predefinidos'),
            const SizedBox(height: 12),
            _buildThemeGrid(
              context,
              state.availableThemes.where((t) => !t.isCustom).toList(),
              state.currentTheme,
            ),
            if (state.availableThemes.any((t) => t.isCustom)) ...[
              const SizedBox(height: 24),
              _buildSectionHeader('Temas Personalizados'),
              const SizedBox(height: 12),
              _buildThemeGrid(
                context,
                state.availableThemes.where((t) => t.isCustom).toList(),
                state.currentTheme,
                showDelete: true,
              ),
            ],
            const SizedBox(height: 24),
            _buildCreateCustomThemeButton(context),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF059669),
      ),
    );
  }

  Widget _buildThemeGrid(
    BuildContext context,
    List<AppTheme> themes,
    AppTheme currentTheme, {
    bool showDelete = false,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes[index];
        final isSelected = theme.id == currentTheme.id;

        return _ThemeCard(
          theme: theme,
          isSelected: isSelected,
          showDelete: showDelete,
          onTap: () => context.read<ThemeBloc>().add(ChangeTheme(theme.id)),
          onDelete: showDelete
              ? () => _showDeleteConfirmation(context, theme)
              : null,
        );
      },
    );
  }

  Widget _buildCreateCustomThemeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => CreateCustomThemeBottomSheet.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Crear Tema Personalizado'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: Theme.of(context).colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppTheme theme) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Tema'),
        content: Text('¿Estás seguro de eliminar el tema "${theme.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ThemeBloc>().add(DeleteCustomTheme(theme.id));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

/// Card individual de tema
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
    this.showDelete = false,
    this.onDelete,
  });

  final AppTheme theme;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showDelete;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? theme.lightColorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.5),
                width: isSelected ? 3 : 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ColorCircle(
                      color: theme.lightColorScheme.primary,
                      borderColor: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 4),
                    _ColorCircle(
                      color: theme.lightColorScheme.secondary,
                      borderColor: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    theme.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? theme.lightColorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isSelected)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.lightColorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 16,
                color: theme.lightColorScheme.onPrimary,
              ),
            ),
          ),
        if (showDelete && onDelete != null)
          Positioned(
            top: 4,
            left: 4,
            child: InkWell(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

/// Círculo de color para vista previa
class _ColorCircle extends StatelessWidget {
  const _ColorCircle({required this.color, required this.borderColor});

  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1),
      ),
    );
  }
}
