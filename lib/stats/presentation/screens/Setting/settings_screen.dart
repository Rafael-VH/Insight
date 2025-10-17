import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/stats/domain/entities/app_settings.dart';
import 'package:insight/stats/presentation/bloc/settings_bloc.dart';
import 'package:insight/stats/presentation/bloc/theme_bloc.dart';
import 'package:insight/stats/presentation/widgets/app_sliver_bar.dart';
import 'package:insight/stats/presentation/widgets/theme_selector_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar configuración al iniciar
    context.read<SettingsBloc>().add(LoadSettings());
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
          BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              if (state is SettingsLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (state is SettingsError) {
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
                        Text(state.message),
                      ],
                    ),
                  ),
                );
              }

              if (state is SettingsLoaded) {
                return _buildSettingsList(context, state.settings);
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

  Widget _buildThemeModeSelector(BuildContext context, AppSettings settings) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        if (themeState is! ThemeLoaded) {
          return const SizedBox.shrink();
        }

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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: AppThemeMode.values.map((mode) {
                    final isSelected = themeState.themeMode == mode;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildThemeModeOption(
                          context: context,
                          mode: mode,
                          isSelected: isSelected,
                          onTap: () {
                            context.read<ThemeBloc>().add(
                              ChangeThemeMode(mode),
                            );
                            context.read<SettingsBloc>().add(
                              UpdateThemeMode(mode),
                            );
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
      },
    );
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
              context.read<SettingsBloc>().add(ResetSettings());
              context.read<ThemeBloc>().add(LoadTheme());
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
