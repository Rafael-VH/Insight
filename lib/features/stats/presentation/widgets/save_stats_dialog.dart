import 'package:flutter/material.dart';

/// Widget que proporciona diálogos reutilizables para guardar estadísticas
class SaveStatsDialog {
  /// Muestra un diálogo de éxito
  static void showSuccess(
    BuildContext context, {
    required String message,
    VoidCallback? onClose,
  }) {
    // Obtener colores del tema
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colorScheme.surface, // Adaptado
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de éxito animado
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green[isDark ? 900 : 100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 50,
                color: Colors.green[isDark ? 300 : 700],
              ),
            ),
            const SizedBox(height: 16),
            // Título
            Text(
              '¡Éxito!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green[isDark ? 300 : 700],
              ),
            ),
            const SizedBox(height: 12),
            // Mensaje
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface, // Adaptado
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Botón de aceptar
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onClose?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Aceptar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra un diálogo de error
  static void showError(
    BuildContext context, {
    required String title,
    required String message,
    String? errorDetails,
    VoidCallback? onRetry,
  }) {
    // Obtener colores del tema
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colorScheme.surface, // Adaptado
        contentPadding: const EdgeInsets.all(24),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de error
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red[isDark ? 900 : 100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 50,
                  color: Colors.red[isDark ? 300 : 700],
                ),
              ),
              const SizedBox(height: 16),
              // Título
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[isDark ? 300 : 700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Mensaje principal
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface, // Adaptado
                  height: 1.5,
                ),
              ),
              // Detalles del error (si existen)
              if (errorDetails != null && errorDetails.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.maxFinite,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[isDark ? 900 : 50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[isDark ? 700 : 200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalles técnicos:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[isDark ? 300 : 700],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        errorDetails,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.red[isDark ? 200 : 600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botón cerrar
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cerrar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botón reintentar (si se proporciona callback)
                  if (onRetry != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onRetry();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Reintentar',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
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

  /// Muestra un diálogo de cargando
  static void showSaving(BuildContext context) {
    // CORRECCIÓN: Obtener colores del tema
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colorScheme.surface, // Adaptado
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de carga
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.primary, // Adaptado
              ),
            ),
            const SizedBox(height: 16),
            // Mensaje
            Text(
              'Guardando estadísticas...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface, // Adaptado
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Subtítulo
            Text(
              'Por favor espera',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6), // Adaptado
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra un diálogo de confirmación antes de guardar
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmButtonText = 'Guardar',
    String cancelButtonText = 'Cancelar',
  }) {
    // Obtener colores del tema
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colorScheme.surface, // Adaptado
        title: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface, // Adaptado
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.8), // Adaptado
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              cancelButtonText,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              confirmButtonText,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de información
  static void showInfo(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'Aceptar',
  }) {
    // Obtener colores del tema
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colorScheme.surface, // Adaptado
        title: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface, // Adaptado
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.8), // Adaptado
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
