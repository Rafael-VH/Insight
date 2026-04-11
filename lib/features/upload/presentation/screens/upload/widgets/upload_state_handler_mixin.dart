import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:insight/features/parser/utils/stats_validator.dart';
import 'package:insight/features/history/presentation/bloc/history_bloc.dart';
import 'package:insight/features/history/presentation/bloc/history_event.dart';
import 'package:insight/features/settings/domain/entities/app_settings.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_state.dart';
import 'package:insight/features/parser/domain/entities/game_mode.dart';
import 'package:insight/features/ocr/presentation/bloc/ocr_state.dart';
import 'package:insight/features/upload/presentation/bloc/upload_bloc.dart';
import 'package:insight/features/upload/presentation/bloc/upload_event.dart';
import 'package:insight/features/upload/presentation/bloc/upload_state.dart';
import 'package:insight/features/upload/presentation/controllers/stats_upload_controller.dart';
import 'package:insight/core/services/dialog_service.dart';
import 'package:insight/features/parser/presentation/utils/game_mode_extensions.dart';
import 'package:insight/features/upload/presentation/widgets/validation_result_dialog.dart';

/// Mixin con toda la lógica de manejo de estados de OCR y Stats BLoC.
///
/// Comportamiento:
/// - El auto-guardado ha sido **eliminado**. El guardado solo ocurre cuando
///   el usuario pulsa explícitamente el botón "Guardar estadísticas".
/// - Al aceptar el diálogo de validación, solo se muestra feedback visual.
/// - La navegación de vuelta al historial ocurre únicamente cuando el
///   guardado explícito es exitoso.
mixin UploadStateHandlerMixin<T extends StatefulWidget> on State<T> {
  StatsUploadController get uploadController;
  bool get isSaving;
  set isSaving(bool value);
  GameMode? get currentValidatingMode;
  set currentValidatingMode(GameMode? value);

  // ── Helpers de configuración ───────────────────────────────────

  AppSettings? get _currentSettings {
    final state = context.read<SettingsBloc>().state;
    return state is SettingsLoaded ? state.settings : null;
  }

  bool get _useAwesome => _currentSettings?.useAwesomeSnackbar ?? true;

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

  /// Guardado exitoso — cierra el loading, muestra éxito y navega de vuelta.
  /// Solo se llega aquí cuando el usuario pulsó "Guardar".
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
  /// y el guardado es exitoso.
  void _navigateBackAfterSave() {
    if (!mounted) return;
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
  /// Al aceptar el diálogo, solo se muestra confirmación visual.
  /// El guardado real ocurre únicamente con el botón explícito.
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

  /// Al aceptar el diálogo de validación, solo muestra feedback visual.
  /// No guarda ni navega automáticamente.
  void _onValidationAccepted(ValidationResult validation, GameMode? mode) {
    final modeName = mode?.fullDisplayName ?? 'el modo seleccionado';

    if (validation.isValid) {
      _showSuccess('✓ Estadísticas de $modeName listas. Pulsa Guardar cuando estés listo.');
    } else {
      _showWarning(
        'Estadísticas de $modeName incompletas. Puedes guardar igualmente o reintentar.',
      );
    }
  }

  void retryImageCapture(GameMode mode) {
    uploadController.removeStats(mode);
    currentValidatingMode = null;
    _showSuccess('Imagen eliminada. Vuelve a capturar para ${mode.fullDisplayName}.');
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
