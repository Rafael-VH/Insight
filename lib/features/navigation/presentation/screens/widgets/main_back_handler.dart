import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:insight/features/navigation/presentation/bloc/navigation_event.dart';

/// Widget que envuelve su [child] con [PopScope] para interceptar
/// el botón de retroceso del sistema y aplicar la lógica de navegación
/// propia: retroceder en el historial, volver al índice 0, o mostrar
/// el diálogo de confirmación de salida.
class MainBackHandler extends StatelessWidget {
  const MainBackHandler({super.key, required this.child});

  final Widget child;

  Future<void> _onPopInvokedWithResult(BuildContext context, bool didPop, dynamic result) async {
    if (didPop) return;

    final navigationBloc = context.read<NavigationBloc>();

    if (navigationBloc.canGoBack) {
      navigationBloc.add(const NavigateBack());
      return;
    }

    if (navigationBloc.currentIndex != 0) {
      navigationBloc.add(const NavigationItemSelected(0));
      return;
    }

    final shouldExit = await _showExitConfirmation(context) ?? false;
    if (shouldExit && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool?> _showExitConfirmation(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('Salir de la aplicación', style: TextStyle(color: colorScheme.onSurface)),
        content: Text(
          '¿Estás seguro de que quieres salir?',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _onPopInvokedWithResult(context, didPop, result),
      child: child,
    );
  }
}
