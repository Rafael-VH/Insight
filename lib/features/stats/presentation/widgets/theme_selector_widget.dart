import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
//
import 'package:insight/features/stats/domain/entities/app_theme.dart';
//
import 'package:insight/features/stats/presentation/bloc/theme_bloc.dart';

/// Widget para seleccionar temas en la configuración
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
            // Sección de temas predefinidos
            _buildSectionHeader('Temas Predefinidos'),
            const SizedBox(height: 12),
            _buildThemeGrid(
              context,
              state.availableThemes.where((t) => !t.isCustom).toList(),
              state.currentTheme,
            ),

            // Sección de temas personalizados
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

            // Botón para crear tema personalizado
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
          onTap: () {
            context.read<ThemeBloc>().add(ChangeTheme(theme.id));
          },
          onDelete: showDelete
              ? () => _showDeleteConfirmation(context, theme)
              : null,
        );
      },
    );
  }

  Widget _buildCreateCustomThemeButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        // TODO: Navegar a pantalla de creación de tema personalizado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Función de crear tema personalizado próximamente'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Crear Tema Personalizado'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Theme.of(context).primaryColor),
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
                    : Colors.grey[300]!,
                width: isSelected ? 3 : 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Muestra de colores
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ColorCircle(color: theme.lightColorScheme.primary),
                    const SizedBox(width: 4),
                    _ColorCircle(color: theme.lightColorScheme.secondary),
                  ],
                ),
                const SizedBox(height: 8),
                // Nombre del tema
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
                          : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Icono de seleccionado
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
        // Botón de eliminar
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
  const _ColorCircle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
    );
  }
}
