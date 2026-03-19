import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:insight/core/utils/stats_validator.dart';
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
/// Se aplica sobre el State de UploadScreen para separar la lógica
/// de presentación sin duplicar código.
mixin UploadStateHandlerMixin<T extends StatefulWidget> on State<T> {
  // Subclases deben proveer acceso al controlador y al flag de guardado
  StatsUploadController get uploadController;
  bool get isSaving;
  set isSaving(bool value);
  GameMode? get currentValidatingMode;
  set currentValidatingMode(GameMode? value);

  // ==================== HELPERS ====================

  bool get _useAwesome {
    final state = context.read<SettingsBloc>().state;
    return state is SettingsLoaded ? state.settings.useAwesomeSnackbar : true;
  }

  // ==================== OCR HANDLERS ====================

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
        message: 'No se pudo determinar el modo de juego',
        errorDetails:
            'Por favor, intenta nuevamente. Si el problema persiste, reinicia la aplicación.',
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
            'No se pudieron extraer las estadísticas completas para ${mode.fullDisplayName}.',
        errorDetails:
            'Verifica que la imagen muestre claramente todas las estadísticas. '
            'Intenta capturar la pantalla con buena iluminación.',
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
      message = 'La imagen no contiene texto legible';
      suggestion =
          'Asegúrate de que la captura sea clara y que las estadísticas sean visibles';
    } else if (state.message.toLowerCase().contains('pick') ||
        state.message.toLowerCase().contains('image')) {
      title = 'Error al Seleccionar Imagen';
      message = 'No se pudo acceder a la imagen';
      suggestion = 'Verifica los permisos de la aplicación en Configuración';
    } else if (state.message.toLowerCase().contains('permission')) {
      title = 'Permisos Requeridos';
      message =
          'La aplicación necesita permisos para acceder a la cámara o galería';
      suggestion =
          'Ve a Configuración > Aplicaciones > ML Stats OCR > Permisos';
    }

    DialogService.showError(
      context,
      title: title,
      message: message,
      errorDetails: suggestion,
      useAwesome: _useAwesome,
    );
  }

  // ==================== STATS BLOC HANDLERS ====================

  void handleStatsState(StatsState state) {
    if (state is StatsSaving) {
      _handleSavingState();
    } else {
      if (isSaving) {
        setState(() => isSaving = false);
      }
      if (state is StatsSaved) {
        _handleSuccessfulSave(state);
      } else if (state is StatsError) {
        _handleSaveError(state);
      }
    }
  }

  void _handleSavingState() {
    if (isSaving) return;
    setState(() => isSaving = true);
    DialogService.showLoading(
      context,
      message: 'Guardando estadísticas...',
      useAwesome: _useAwesome,
    );
  }

  void _handleSuccessfulSave(StatsSaved state) async {
    await _safelyCloseDialog();
    if (!mounted) return;

    DialogService.showSuccess(
      context,
      message: state.message,
      useAwesome: _useAwesome,
      onClose: () => _navigateBackToHome(),
    );
  }

  void _handleSaveError(StatsError state) async {
    await _safelyCloseDialog();
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

  Future<void> _safelyCloseDialog() async {
    if (!mounted) return;
    try {
      await Future.delayed(Duration.zero);
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (_) {}
  }

  void _navigateBackToHome() {
    if (!mounted) return;
    Navigator.of(context).pop();
    context.read<StatsBloc>().add(LoadAllStatsCollectionsEvent());
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  // ==================== ACCIONES PÚBLICAS ====================

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
        message: 'Carga al menos una estadística antes de guardar.',
        useAwesome: _useAwesome,
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      context.read<StatsBloc>().add(SaveStatsCollectionEvent(collection));
    }
  }

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
      onAccept: () {
        if (currentValidatingMode != null) {
          if (validation.isValid) {
            _showSuccess(
              uploadController.getSuccessMessage(currentValidatingMode!),
            );
          } else {
            _showWarning('Estadísticas guardadas con datos incompletos');
          }
        }
      },
    );
  }

  void retryImageCapture(GameMode mode) {
    uploadController.removeStats(mode);
    currentValidatingMode = null;
    _showSuccess('Por favor, vuelve a capturar la imagen');
  }

  void _showSuccess(String message) {
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
    if (_useAwesome) {
      DialogService.showWarning(
        context,
        message: message,
        title: '⚠️ Advertencia',
      );
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
