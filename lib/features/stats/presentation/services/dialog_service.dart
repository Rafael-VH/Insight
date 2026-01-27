import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:insight/features/stats/presentation/widgets/save_stats_dialog.dart';

/// Servicio unificado para mostrar diálogos con soporte para awesome_snackbar_content
class DialogService {
  static const Duration _defaultDuration = Duration(seconds: 3);

  /// Muestra un diálogo de éxito
  static Future<void> showSuccess(
    BuildContext context, {
    required String message,
    bool useAwesome = true,
    VoidCallback? onClose,
    Duration duration = _defaultDuration,
  }) async {
    if (useAwesome) {
      _showAwesomeSuccess(context, message, duration);
    } else {
      SaveStatsDialog.showSuccess(context, message: message, onClose: onClose);
    }
  }

  /// Muestra un diálogo de error
  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    String? errorDetails,
    bool useAwesome = true,
    VoidCallback? onRetry,
    Duration duration = _defaultDuration,
  }) async {
    if (useAwesome) {
      _showAwesomeError(context, title, message, errorDetails, duration);
    } else {
      SaveStatsDialog.showError(
        context,
        title: title,
        message: message,
        errorDetails: errorDetails,
        onRetry: onRetry,
      );
    }
  }

  /// Muestra un diálogo de cargando
  static Future<void> showLoading(
    BuildContext context, {
    String message = 'Guardando estadísticas...',
    bool useAwesome = true,
  }) async {
    if (useAwesome) {
      _showAwesomeLoading(context, message);
    } else {
      SaveStatsDialog.showSaving(context);
    }
  }

  /// Muestra un diálogo de confirmación
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmButtonText = 'Guardar',
    String cancelButtonText = 'Cancelar',
    bool useAwesome = true,
  }) async {
    if (useAwesome) {
      return _showAwesomeConfirmation(
        context,
        title,
        message,
        confirmButtonText,
        cancelButtonText,
      );
    } else {
      return SaveStatsDialog.showConfirmation(
        context,
        title: title,
        message: message,
        confirmButtonText: confirmButtonText,
        cancelButtonText: cancelButtonText,
      );
    }
  }

  /// ========== IMPLEMENTACIONES AWESOME SNACKBAR ==========

  static void _showAwesomeSuccess(
    BuildContext context,
    String message,
    Duration duration,
  ) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      duration: duration,
      content: AwesomeSnackbarContent(
        title: '¡Éxito!',
        message: message,
        contentType: ContentType.success,
        inMaterialBanner: false,
      ),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    }
  }

  static void _showAwesomeError(
    BuildContext context,
    String title,
    String message,
    String? errorDetails,
    Duration duration,
  ) {
    final displayMessage = errorDetails != null && errorDetails.isNotEmpty
        ? '$message\n\n$errorDetails'
        : message;

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      duration: duration,
      content: AwesomeSnackbarContent(
        title: title,
        message: displayMessage,
        contentType: ContentType.failure,
        inMaterialBanner: false,
      ),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    }
  }

  static void _showAwesomeLoading(BuildContext context, String message) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      duration: const Duration(minutes: 1),
      content: AwesomeSnackbarContent(
        title: 'Procesando...',
        message: message,
        contentType: ContentType.help,
        inMaterialBanner: false,
      ),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    }
  }

  static Future<bool?> _showAwesomeConfirmation(
    BuildContext context,
    String title,
    String message,
    String confirmButtonText,
    String cancelButtonText,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              cancelButtonText,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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

  /// ========== MÉTODOS DE CONVENIENCIA PARA SNACKBARS ==========

  static void showCustomSnackbar(
    BuildContext context, {
    required String title,
    required String message,
    required ContentType contentType,
    Duration duration = _defaultDuration,
  }) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      duration: duration,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: contentType,
        inMaterialBanner: false,
      ),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    }
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    String title = '⚠️ Advertencia',
    Duration duration = _defaultDuration,
  }) {
    showCustomSnackbar(
      context,
      title: title,
      message: message,
      contentType: ContentType.warning,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    String title = 'ℹ️ Información',
    Duration duration = _defaultDuration,
  }) {
    showCustomSnackbar(
      context,
      title: title,
      message: message,
      contentType: ContentType.help,
      duration: duration,
    );
  }
}
