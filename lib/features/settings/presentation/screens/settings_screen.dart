import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
//
import 'package:insight/features/settings/domain/entities/app_settings.dart';
//
import 'package:insight/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/theme_bloc.dart';
//
import 'package:insight/features/stats/presentation/widgets/app_sliver_bar.dart';
import 'package:insight/features/stats/presentation/widgets/theme_selector_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // MEJORADO: Cargar configuración al iniciar
    _loadSettings();
  }

  void _loadSettings() {
    if (mounted) {
      context.read<SettingsBloc>().add(LoadSettings());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverBar(
            title: 'Configuración',
            colors: const [Color(0xFF7C3AED), Color(0xFF9333EA)],
            icon: Icons.settings,
          ),
          // MEJORADO: Solo un BlocBuilder para SettingsBloc
          BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, settingsState) {
              if (settingsState is SettingsLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (settingsState is SettingsError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar configuración',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(settingsState.message),
                      ],
                    ),
                  ),
                );
              }

              if (settingsState is SettingsLoaded) {
                return _buildSettingsList(context, settingsState.settings);
              }

              return const SliverFillRemaining(
                child: Center(child: Text('Cargando...')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, AppSettings settings) {
    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 16),

        // Sección: Apariencia
        _buildSectionHeader('Apariencia'),
        const SizedBox(height: 12),

        // Selector de modo de tema (Claro/Oscuro/Sistema)
        _buildThemeModeSelector(context, settings),
        const SizedBox(height: 16),

        // Selector de tema (Colores)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.color_lens_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Tema de Color',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const ThemeSelectorWidget(),
                ],
              ),
            ),
          ),
        ),

        const Divider(height: 32),

        // Sección: General
        _buildSectionHeader('General'),
        _buildSwitchTile(
          context: context,
          icon: Icons.notifications_outlined,
          title: 'Notificaciones',
          subtitle: 'Recibir alertas y recordatorios',
          value: settings.enableNotifications,
          onChanged: (value) {
            context.read<SettingsBloc>().add(UpdateNotifications(value));
          },
        ),
        _buildSwitchTile(
          context: context,
          icon: Icons.vibration,
          title: 'Vibración',
          subtitle: 'Feedback háptico en interacciones',
          value: settings.enableHapticFeedback,
          onChanged: (value) {
            context.read<SettingsBloc>().add(UpdateHapticFeedback(value));
          },
        ),
        _buildSwitchTile(
          context: context,
          icon: Icons.save_outlined,
          title: 'Auto-guardar',
          subtitle: 'Guardar estadísticas automáticamente',
          value: settings.autoSaveStats,
          onChanged: (value) {
            context.read<SettingsBloc>().add(UpdateAutoSave(value));
          },
        ),

        // NUEVO: Switch para estilo de diálogos
        _buildSwitchTile(
          context: context,
          icon: Icons.chat_bubble_outline,
          title: 'Diálogos Mejorados',
          subtitle: 'Usar estilo Awesome Snackbar para notificaciones',
          value: settings.useAwesomeSnackbar,
          onChanged: (value) {
            context.read<SettingsBloc>().add(UpdateAwesomeSnackbar(value));

            // Mostrar preview del nuevo estilo
            _showStylePreview(context, value);
          },
        ),

        const Divider(height: 32),

        // Sección: Acerca de
        _buildSectionHeader('Acerca de'),
        _buildInfoTile(
          icon: Icons.info_outline,
          title: 'Versión',
          subtitle: '1.0.0+1',
        ),
        _buildInfoTile(
          icon: Icons.bug_report_outlined,
          title: 'Reportar un problema',
          subtitle: 'Ayúdanos a mejorar la app',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Función en desarrollo')),
            );
          },
        ),
        const Divider(height: 32),

        // Botón de restablecer
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: () => _showResetDialog(context),
            icon: const Icon(Icons.restore),
            label: const Text('Restablecer configuración'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  // NUEVO: Método para mostrar preview del estilo seleccionado
  void _showStylePreview(BuildContext context, bool useAwesome) {
    if (useAwesome) {
      _showAwesomePreview(context);
    } else {
      _showClassicPreview(context);
    }
  }

  // NUEVO: Preview del estilo Awesome
  void _showAwesomePreview(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estilo Awesome Activado',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Disfrutarás de notificaciones más modernas',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NUEVO: Preview del estilo clásico
  void _showClassicPreview(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Usando diálogos clásicos'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF7C3AED),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // MEJORADO: Selector de modo de tema sin conflictos
  Widget _buildThemeModeSelector(BuildContext context, AppSettings settings) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.brightness_6_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Modo de Tema',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: AppThemeMode.values.map((mode) {
                final isSelected = settings.themeMode == mode;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildThemeModeOption(
                      context: context,
                      mode: mode,
                      isSelected: isSelected,
                      onTap: () {
                        // MEJORADO: Actualizar ambos blocs de forma sincronizada
                        _updateThemeMode(context, mode);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // NUEVO: Método para actualizar el modo de tema
  void _updateThemeMode(BuildContext context, AppThemeMode mode) {
    if (mounted) {
      // Primero actualizar SettingsBloc
      context.read<SettingsBloc>().add(UpdateThemeMode(mode));

      // Luego actualizar ThemeBloc
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          context.read<ThemeBloc>().add(ChangeThemeMode(mode));
        }
      });
    }
  }

  Widget _buildThemeModeOption({
    required BuildContext context,
    required AppThemeMode mode,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              mode.icon,
              color: isSelected ? colorScheme.primary : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              mode.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colorScheme.primary : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.grey[700]),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restablecer configuración'),
        content: const Text(
          '¿Estás seguro de que quieres restablecer toda la configuración a los valores predeterminados?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // MEJORADO: Resetear ambos blocs correctamente
              context.read<SettingsBloc>().add(ResetSettings());

              // Pequeño delay para asegurar que SettingsBloc se actualiza primero
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  context.read<ThemeBloc>().add(LoadTheme());
                }
              });

              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Configuración restablecida'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );
  }
}
