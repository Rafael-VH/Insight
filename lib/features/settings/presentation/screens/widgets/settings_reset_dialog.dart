import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_event.dart';
import 'package:insight/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/theme/theme_event.dart';

class SettingsResetDialog {
  const SettingsResetDialog._();

  /// Muestra el diálogo de confirmación y ejecuta el reset si el usuario acepta.
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restablecer configuración'),
        content: const Text(
          '¿Estás seguro de que quieres restablecer toda la configuración '
          'a los valores predeterminados?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              context.read<SettingsBloc>().add(ResetSettings());

              // Pequeño delay para que SettingsBloc se actualice primero
              Future.delayed(const Duration(milliseconds: 100), () {
                if (context.mounted) {
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
