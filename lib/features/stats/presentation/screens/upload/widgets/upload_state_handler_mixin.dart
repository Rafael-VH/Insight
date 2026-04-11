import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:insight/core/utils/stats_validator.dart';
import 'package:insight/features/history/presentation/bloc/history_bloc.dart';
import 'package:insight/features/history/presentation/bloc/history_event.dart';
import 'package:insight/features/settings/domain/entities/app_settings.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_state.dart';
import 'package:insight/features/stats/domain/entities/game_mode.dart';
import 'package:insight/features/stats/presentation/bloc/ocr/ocr_state.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_bloc.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_event.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_state.dart';
import 'package:insight/features/stats/presentation/controllers/stats_upload_controller.dart';
import 'package:insight/features/stats/presentation/services/dialog_service.dart';
import 'package:insight/features/stats/presentation/utils/game_mode_extensions.dart';
import 'package:insight/features/stats/presentation/widgets/validation_result_dialog.dart';

/// Mixin con toda la lógica de manejo de estados de OCR y Stats BLoC.
///
/// Comportamiento corregido:
/// - [autoSaveStats] = true  → guarda automáticamente al aceptar la
///   validación, pero NO navega fuera; el usuario sigue en la pantalla
///   para poder cargar más modos de juego.
/// - [autoSaveStats] = false → nunca guarda automáticamente; el usuario
///   debe pulsar el botón "Guardar estadísticas" explícitamente.
/// - El botón de guardar siempre está disponible mientras haya al menos
///   una stat procesada, independientemente de [autoSaveStats].
/// - Navegar de vuelta al historial ocurre únicamente cuando el usuario
///   pulsa el botón de guardar y el guardado es exitoso.
mixin UploadStateHandlerMixin<T extends StatefulWidget> on State<T> {
  StatsUploadController get uploadController;
  bool get isSaving;
  set isSaving(bool value);
  GameMode? get currentValidatingMode;
  set currentValidatingMode(GameMode? value);

  // ── Helpers de configuración ───────────────────────────────────

  /// Lee la configuración actual de forma segura.
  AppSettings? get _currentSettings {
    final state = context.read<SettingsBloc>().state;
    return state is SettingsLoaded ? state.settings : null;
  }

  bool get _useAwesome => _currentSettings?.useAwesomeSnackbar ?? true;

  /// Determina si se debe guardar automáticamente al aceptar
  /// el diálogo de validación.
  bool get _autoSave => _currentSettings?.autoSaveStats ?? true;

  // ── OCR Handlers ───────────────────────────────────────────────

  void handleOcrState(OcrState state) {
    if (state is OcrSuccess) {
      _handleOcrSuccess(state);
    } else if (state is OcrError) {
      _handleOcrError(state);
    }
  }

  void _handleOcrSuccess(OcrSuccess state) {
    final result = uploadController.handleOcrSuccessWithDiagnostics(
      state.result.recognizedText,
      state.result.imagePath,
    );

    final mode = result.processedMode;

    if (mode == null) {
      DialogService.showError(
        context,
        title: 'Error Interno',
        message: 'No se pudo determinar el modo de juego.',
        errorDetails:
            'Por favor, intenta nuevamente. Si el problema persiste, '
            'reinicia la aplicación.',
        useAwesome: _useAwesome,
      );
      return;
    }

    if (result.hasValidStats && result.validation != null) {
      // Pequeño delay para que el widget de imagen termine de renderizar
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          currentValidatingMode = mode;
          showValidationDialog(result.validation!, mode);
        }
      });
    } else {
      DialogService.showError(
        context,
        title: 'Error en Extracción',
        message:
            'No se pudieron extraer estadísticas completas para '
            '${mode.fullDisplayName}.',
        errorDetails:
            'Verifica que la imagen muestre claramente todas las '
            'estadísticas. Intenta capturar con buena iluminación.',
        useAwesome: _useAwesome,
        onRetry: () => retryImageCapture(mode),
      );
    }
  }

  void _handleOcrError(OcrError state) {
    uploadController.handleOcrError();

    String title = 'Error en OCR';
    String message = state.message;
    String? suggestion;

    if (state.message.toLowerCase().contains('no text')) {
      title = 'No se Detectó Texto';
      message = 'La imagen no contiene texto legible.';
      suggestion =
          'Asegúrate de que la captura sea clara y que las '
          'estadísticas sean visibles.';
    } else if (state.message.toLowerCase().contains('pick') ||
        state.message.toLowerCase().contains('image')) {
      title = 'Error al Seleccionar Imagen';
      message = 'No se pudo acceder a la imagen.';
      suggestion = 'Verifica los permisos de la aplicación en Configuración.';
    } else if (state.message.toLowerCase().contains('permission')) {
      title = 'Permisos Requeridos';
      message =
          'La aplicación necesita permisos para acceder a la cámara '
          'o galería.';
      suggestion = 'Ve a Configuración > Aplicaciones > Insight > Permisos.';
    }

    DialogService.showError(
      context,
      title: title,
      message: message,
      errorDetails: suggestion,
      useAwesome: _useAwesome,
    );
  }

  // ── Stats BLoC Handlers ────────────────────────────────────────

  void handleStatsState(StatsState state) {
    if (state is StatsSaving) {
      _handleSavingState();
    } else {
      if (isSaving) isSaving = false;

      if (state is StatsSaved) {
        _handleSuccessfulSave(state);
      } else if (state is StatsError) {
        _handleSaveError(state);
      }
    }
  }

  void _handleSavingState() {
    if (isSaving) return;
    isSaving = true;
    DialogService.showLoading(
      context,
      message: 'Guardando estadísticas...',
      useAwesome: _useAwesome,
    );
  }

  /// Guardado exitoso — cierra el loading, muestra éxito y navega de vuelta. Solo se llega aquí cuando el usuario pulsó "Guardar".
  void _handleSuccessfulSave(StatsSaved state) async {
    await _safelyCloseLoadingDialog();
    if (!mounted) return;

    DialogService.showSuccess(
      context,
      message: state.message,
      useAwesome: _useAwesome,
      onClose: _navigateBackAfterSave,
    );
  }

  void _handleSaveError(StatsError state) async {
    await _safelyCloseLoadingDialog();
    if (!mounted) return;

    DialogService.showError(
      context,
      title: 'Error al Guardar',
      message: state.message,
      errorDetails: state.errorDetails,
      useAwesome: _useAwesome,
      onRetry: isSaving ? null : saveStats,
    );
  }

  Future<void> _safelyCloseLoadingDialog() async {
    if (!mounted) return;
    try {
      await Future.delayed(Duration.zero);
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (_) {}
  }

  /// Navega de vuelta solo después de que el usuario pulsa "Guardar"
  /// y el guardado es exitoso. NO se llama desde el diálogo de
  /// validación automática.
  void _navigateBackAfterSave() {
    if (!mounted) return;
    // Recargar historial y volver una sola pantalla atrás
    context.read<HistoryBloc>().add(LoadAllStatsCollectionsEvent());
    Navigator.of(context).pop();
  }

  // ── Acciones públicas ──────────────────────────────────────────

  /// Guarda la colección completa. Solo se llama desde el botón
  /// explícito de la UI — nunca de forma automática.
  Future<void> saveStats() async {
    if (isSaving) {
      _showWarning('Ya se está guardando...');
      return;
    }

    final collection = uploadController.createCollection();

    if (!collection.hasAnyStats) {
      DialogService.showError(
        context,
        title: 'Sin Estadísticas',
        message: 'Carga al menos una imagen antes de guardar.',
        useAwesome: _useAwesome,
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    context.read<StatsBloc>().add(SaveStatsCollectionEvent(collection));
  }

  /// Muestra el diálogo de validación tras procesar una imagen.
  ///
  /// Si [autoSaveStats] está activado en Settings, al aceptar el
  /// diálogo se guarda automáticamente en segundo plano y se muestra
  /// un snackbar — pero NO se navega fuera de la pantalla, permitiendo
  /// al usuario cargar los demás modos de juego.
  ///
  /// Si [autoSaveStats] está desactivado, al aceptar solo se muestra
  /// confirmación visual; el guardado real ocurre con el botón.
  void showValidationDialog(ValidationResult validation, GameMode? mode) {
    if (mode != null) currentValidatingMode = mode;

    ValidationResultDialog.show(
      context: context,
      result: validation,
      useAwesome: _useAwesome,
      onRetry: () {
        if (currentValidatingMode != null) {
          retryImageCapture(currentValidatingMode!);
        }
      },
      onAccept: () => _onValidationAccepted(validation, mode),
    );
  }

  /// Lógica al aceptar el diálogo de validación.
  ///
  /// - Siempre muestra feedback visual del resultado de la extracción.
  /// - Si autoSave está activo, guarda en segundo plano SIN navegar.
  /// - Si autoSave está inactivo, solo muestra el feedback.
  void _onValidationAccepted(ValidationResult validation, GameMode? mode) {
    final modeName = mode?.fullDisplayName ?? 'el modo seleccionado';

    if (validation.isValid) {
      _showSuccess('✓ Estadísticas de $modeName listas para guardar.');
    } else {
      _showWarning('Estadísticas de $modeName guardadas con datos incompletos.');
    }

    // Auto-guardado en segundo plano: guarda pero NO navega.
    // La navegación solo ocurre con el botón explícito.
    if (_autoSave && mounted) {
      _autoSaveInBackground();
    }
  }

  /// Guarda en segundo plano sin afectar la navegación.
  /// El usuario sigue en la pantalla de upload para poder
  /// cargar los demás modos de juego.
  void _autoSaveInBackground() {
    final collection = uploadController.createCollection();
    if (!collection.hasAnyStats) return;

    // Usamos el BLoC directamente sin esperar el estado de "saving"
    // para no bloquear la UI ni mostrar el loading dialog.
    context.read<StatsBloc>().add(SaveStatsCollectionEvent(collection));
  }

  void retryImageCapture(GameMode mode) {
    uploadController.removeStats(mode);
    currentValidatingMode = null;
    _showSuccess('Imagen eliminada. Vuelve a capturar para $mode.');
  }

  // ── Helpers de feedback ────────────────────────────────────────

  void _showSuccess(String message) {
    if (!mounted) return;
    if (_useAwesome) {
      DialogService.showSuccess(context, message: message, useAwesome: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showWarning(String message) {
    if (!mounted) return;
    if (_useAwesome) {
      DialogService.showWarning(context, message: message, title: '⚠️ Advertencia');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
