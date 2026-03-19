import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/settings/domain/entities/app_settings.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_event.dart';
import 'package:insight/features/settings/presentation/widgets/theme_selector_widget.dart';

import 'settings_info_tile.dart';
import 'settings_reset_dialog.dart';
import 'settings_section_header.dart';
import 'settings_style_preview.dart';
import 'settings_switch_tile.dart';
import 'settings_theme_mode_selector.dart';

/// Lista completa de configuraciones organizada en secciones.
/// Recibe [settings] del BLoC padre y delega cada acción al BLoC correspondiente.
class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 16),

        // ── Apariencia ──────────────────────────────────────────
        const SettingsSectionHeader(title: 'Apariencia'),
        const SizedBox(height: 12),
        SettingsThemeModeSelector(currentMode: settings.themeMode),
        const SizedBox(height: 16),
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

        // ── General ─────────────────────────────────────────────
        const SettingsSectionHeader(title: 'General'),
        SettingsSwitchTile(
          icon: Icons.notifications_outlined,
          title: 'Notificaciones',
          subtitle: 'Recibir alertas y recordatorios',
          value: settings.enableNotifications,
          onChanged: (value) =>
              context.read<SettingsBloc>().add(UpdateNotifications(value)),
        ),
        SettingsSwitchTile(
          icon: Icons.vibration,
          title: 'Vibración',
          subtitle: 'Feedback háptico en interacciones',
          value: settings.enableHapticFeedback,
          onChanged: (value) =>
              context.read<SettingsBloc>().add(UpdateHapticFeedback(value)),
        ),
        SettingsSwitchTile(
          icon: Icons.save_outlined,
          title: 'Auto-guardar',
          subtitle: 'Guardar estadísticas automáticamente',
          value: settings.autoSaveStats,
          onChanged: (value) =>
              context.read<SettingsBloc>().add(UpdateAutoSave(value)),
        ),
        SettingsSwitchTile(
          icon: Icons.chat_bubble_outline,
          title: 'Diálogos Mejorados',
          subtitle: 'Usar estilo Awesome Snackbar para notificaciones',
          value: settings.useAwesomeSnackbar,
          onChanged: (value) =>
              context.read<SettingsBloc>().add(UpdateAwesomeSnackbar(value)),
          onPreviewStyle: SettingsStylePreview.show,
        ),

        const Divider(height: 32),

        // ── Acerca de ────────────────────────────────────────────
        const SettingsSectionHeader(title: 'Acerca de'),
        const SettingsInfoTile(
          icon: Icons.info_outline,
          title: 'Versión',
          subtitle: '1.0.0+1',
        ),
        SettingsInfoTile(
          icon: Icons.bug_report_outlined,
          title: 'Reportar un problema',
          subtitle: 'Ayúdanos a mejorar la app',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Función en desarrollo')),
          ),
        ),

        const Divider(height: 32),

        // ── Reset ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: () => SettingsResetDialog.show(context),
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
}
