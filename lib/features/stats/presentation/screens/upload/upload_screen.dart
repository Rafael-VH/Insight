import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/core/utils/stats_validator.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_bloc.dart';
import 'package:insight/features/settings/presentation/bloc/setting/settings_state.dart';
import 'package:insight/features/stats/domain/entities/game_mode.dart';
import 'package:insight/features/stats/domain/entities/image_source_type.dart';
import 'package:insight/features/stats/domain/entities/stats_upload_type.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_bloc.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_event.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_state.dart';
import 'package:insight/features/stats/presentation/bloc/ocr/ocr_bloc.dart';
import 'package:insight/features/stats/presentation/bloc/ocr/ocr_event.dart';
import 'package:insight/features/stats/presentation/bloc/ocr/ocr_state.dart';
import 'package:insight/features/stats/presentation/controllers/stats_upload_controller.dart';
import 'package:insight/features/stats/presentation/services/dialog_service.dart';
import 'package:insight/features/stats/presentation/utils/game_mode_extensions.dart';
import 'package:insight/features/stats/presentation/widgets/image_upload_card.dart';
import 'package:insight/features/stats/presentation/widgets/stats_verification_widget.dart';
import 'package:insight/features/stats/presentation/widgets/validation_result_dialog.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key, required this.uploadType});

  final StatsUploadType uploadType;

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  late final StatsUploadController _controller;
  bool _isSaving = false;

  GameMode? _currentValidatingMode;

  Timer? _validationDebounceTimer;

  Timer? _saveTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _controller = StatsUploadController(uploadType: widget.uploadType);
  }

  @override
  void dispose() {
    _validationDebounceTimer?.cancel();
    _saveTimeoutTimer?.cancel();

    // Limpiar controller y estado
    _controller.dispose();
    _currentValidatingMode = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OcrBloc, OcrState>(
      listener: _handleOcrState,
      child: BlocListener<StatsBloc, StatsState>(
        listener: _handleMlStatsState,
        child: Scaffold(
          appBar: _buildAppBar(),
          body: ListenableBuilder(
            listenable: _controller,
            builder: (context, child) => _buildBody(),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(widget.uploadType.appBarTitle),
      actions: [
        if (_controller.hasAnyParsedStats)
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showValidationSummary,
            tooltip: 'Ver resumen de validación',
          ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._buildImageUploadCards(),
          const SizedBox(height: 16),
          if (_controller.hasAnyParsedStats) ...[
            _buildStatsSection(),
            const SizedBox(height: 16),
            _buildSaveButton(),
          ],
        ],
      ),
    );
  }

  void _handleOcrState(BuildContext context, OcrState state) {
    final settingsState = context.read<SettingsBloc>().state;
    final useAwesome = settingsState is SettingsLoaded
        ? settingsState.settings.useAwesomeSnackbar
        : true;

    if (state is OcrSuccess) {
      _handleOcrSuccess(context, state, useAwesome);
    } else if (state is OcrError) {
      _handleOcrError(context, state, useAwesome);
    }
  }

  void _handleOcrSuccess(
    BuildContext context,
    OcrSuccess state,
    bool useAwesome,
  ) {

    final result = _controller.handleOcrSuccessWithDiagnostics(
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
        useAwesome: useAwesome,
      );
      return;
    }

    if (result.hasValidStats && result.validation != null) {
      _validationDebounceTimer?.cancel();
      _validationDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          _currentValidatingMode = mode;
          _showValidationDialog(result.validation!, mode);
        }
      });
    } else {

      // Mensaje de error más específico con opción de reintentar
      DialogService.showError(
        context,
        title: 'Error en Extracción',
        message:
            'No se pudieron extraer las estadísticas completas para ${mode.fullDisplayName}.',
        errorDetails:
            'Verifica que la imagen muestre claramente todas las estadísticas. Intenta capturar la pantalla con buena iluminación.',
        useAwesome: useAwesome,
        onRetry: () => _retryImageCapture(mode),
      );
    }
  }

  void _handleOcrError(BuildContext context, OcrError state, bool useAwesome) {
    _controller.handleOcrError();

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
      useAwesome: useAwesome,
    );
  }

  void _handleMlStatsState(BuildContext context, StatsState state) {
    final settingsState = context.read<SettingsBloc>().state;
    final useAwesome = settingsState is SettingsLoaded
        ? settingsState.settings.useAwesomeSnackbar
        : true;

    if (state is StatsSaving) {
      _handleSavingState(context, useAwesome);
    } else {
      if (_isSaving) {
        setState(() => _isSaving = false);
        _saveTimeoutTimer?.cancel();
      }

      if (state is StatsSaved) {
        _handleSuccessfulSave(context, state, useAwesome);
      } else if (state is StatsError) {
        _handleSaveError(context, state, useAwesome);
      }
    }
  }

  void _handleSavingState(BuildContext context, bool useAwesome) {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    _saveTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_isSaving && mounted) {
        setState(() => _isSaving = false);
        _safelyCloseDialog(context);
        DialogService.showError(
          context,
          title: 'Tiempo Agotado',
          message: 'El guardado tomó demasiado tiempo',
          errorDetails: 'Por favor, intenta nuevamente',
          useAwesome: useAwesome,
          onRetry: _saveStats,
        );
      }
    });

    DialogService.showLoading(
      context,
      message: 'Guardando estadísticas...',
      useAwesome: useAwesome,
    );
  }

  void _handleSuccessfulSave(
    BuildContext context,
    StatsSaved state,
    bool useAwesome,
  ) async {
    await _safelyCloseDialog(context);
    if (!mounted) return;

    DialogService.showSuccess(
      context,
      message: state.message,
      useAwesome: useAwesome,
      onClose: () => _navigateBackToHome(context),
    );
  }

  void _handleSaveError(
    BuildContext context,
    StatsError state,
    bool useAwesome,
  ) async {
    await _safelyCloseDialog(context);
    if (!mounted) return;

    DialogService.showError(
      context,
      title: 'Error al Guardar',
      message: state.message,
      errorDetails: state.errorDetails,
      useAwesome: useAwesome,
      onRetry: _isSaving ? null : _saveStats,
    );
  }

  Future<void> _safelyCloseDialog(BuildContext context) async {
    if (!mounted) return;
    try {
      await Future.delayed(Duration.zero);
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      debugPrint('⚠️ Error al cerrar diálogo: $e');
    }
  }

  void _navigateBackToHome(BuildContext context) {
    if (!mounted) return;
    Navigator.of(context).pop();
    context.read<StatsBloc>().add(LoadAllStatsCollectionsEvent());
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  Future<void> _saveStats() async {
    if (_isSaving) {
      _showWarningSnackBar('Ya se está guardando...');
      return;
    }

    final collection = _controller.createCollection();

    if (!collection.hasAnyStats) {
      final settingsState = context.read<SettingsBloc>().state;
      final useAwesome = settingsState is SettingsLoaded
          ? settingsState.settings.useAwesomeSnackbar
          : true;

      DialogService.showError(
        context,
        title: 'Sin Estadísticas',
        message: 'Carga al menos una estadística antes de guardar.',
        useAwesome: useAwesome,
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      context.read<StatsBloc>().add(SaveStatsCollectionEvent(collection));
    }
  }

  List<Widget> _buildImageUploadCards() {
    return _controller.availableModes.map((mode) {
      final isProcessing = _controller.isProcessing[mode] ?? false;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Stack(
          children: [
            ImageUploadCard(
              key: ValueKey(mode),
              gameMode: mode,
              imagePath: _controller.uploadedImages[mode],
              isProcessing: isProcessing,
              onUploadPressed: (source) => _onImageUploadPressed(source, mode),
            ),
            if (isProcessing)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Procesando imagen...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Extrayendo estadísticas de ${mode.fullDisplayName}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            if (!isProcessing && _controller.validationResults[mode] != null)
              Positioned(
                top: 12,
                right: 12,
                child: _buildValidationBadge(
                  _controller.validationResults[mode]!,
                  mode,
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildValidationBadge(ValidationResult validation, GameMode mode) {
    final IconData icon;
    final Color color;

    if (validation.isValid && validation.warningFields.isEmpty) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (validation.isValid) {
      icon = Icons.warning;
      color = Colors.orange;
    } else {
      icon = Icons.error;
      color = Colors.red;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _showValidationDialog(validation, mode),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildStatsSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Estadísticas extraídas:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            if (_controller.hasInvalidStats())
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.orange[900]!.withValues(alpha: 0.4)
                      : Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: isDark ? Colors.orange[300] : Colors.orange[900],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Datos incompletos',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.orange[300] : Colors.orange[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ..._buildVerificationWidgets(),
      ],
    );
  }

  List<Widget> _buildVerificationWidgets() {
    return _controller.parsedStats.entries
        .where((entry) => entry.value != null)
        .map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: StatsVerificationWidget(
              gameMode: entry.key,
              stats: entry.value!,
            ),
          );
        })
        .toList();
  }

  Widget _buildSaveButton() {
    final hasInvalid = _controller.hasInvalidStats();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasInvalid)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.orange[900]!.withValues(alpha: 0.3)
                  : Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.orange[700]! : Colors.orange[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isDark ? Colors.orange[300] : Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Algunos datos están incompletos. Puedes guardar de todos modos o reintentar la captura.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.orange[200] : Colors.orange[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveStats,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isSaving
                ? colorScheme.onSurface.withValues(alpha: 0.12)
                : hasInvalid
                ? Colors.orange
                : const Color(0xFF059669),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            disabledBackgroundColor:
                colorScheme.onSurface.withValues(alpha: 0.12),
            disabledForegroundColor:
                colorScheme.onSurface.withValues(alpha: 0.38),
          ),
          child: _isSaving
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Guardando...'),
                  ],
                )
              : Text(
                  hasInvalid
                      ? 'Guardar con Datos Incompletos'
                      : 'Guardar Estadísticas',
                ),
        ),
      ],
    );
  }

  void _onImageUploadPressed(ImageSourceType source, GameMode mode) {
    _controller.startProcessing(mode);
    context.read<OcrBloc>().add(ProcessImageEvent(source));
  }

  void _showValidationDialog(ValidationResult validation, GameMode? mode) {
    final settingsState = context.read<SettingsBloc>().state;
    final useAwesome = settingsState is SettingsLoaded
        ? settingsState.settings.useAwesomeSnackbar
        : true;

    if (mode != null) {
      _currentValidatingMode = mode;
    }

    ValidationResultDialog.show(
      context: context,
      result: validation,
      useAwesome: useAwesome,
      onRetry: () {
        if (_currentValidatingMode != null) {
          _retryImageCapture(_currentValidatingMode!);
        }
      },
      onAccept: () {
        if (_currentValidatingMode != null) {
          if (validation.isValid) {
            _showSuccessSnackBar(
              _controller.getSuccessMessage(_currentValidatingMode!),
            );
          } else {
            _showWarningSnackBar(
              'Estadísticas guardadas con datos incompletos',
            );
          }
        }
      },
    );
  }

  void _retryImageCapture(GameMode mode) {
    _controller.removeStats(mode);
    _currentValidatingMode = null;
    _showSuccessSnackBar('Por favor, vuelve a capturar la imagen');
  }

  void _showValidationSummary() {
    final buffer = StringBuffer();
    buffer.writeln('Resumen de Validación\n');

    for (final mode in _controller.availableModes) {
      final validation = _controller.getValidationResult(mode);
      if (validation != null) {
        buffer.writeln('${mode.name}:');
        buffer.writeln('  ${validation.summary}');
        buffer.writeln(
          '  Completitud: ${validation.completionPercentage.toStringAsFixed(1)}%',
        );
        buffer.writeln();
      }
    }

    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Resumen de Validación',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: SingleChildScrollView(
          child: Text(
            buffer.toString(),
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    final settingsState = context.read<SettingsBloc>().state;
    final useAwesome = settingsState is SettingsLoaded
        ? settingsState.settings.useAwesomeSnackbar
        : true;

    if (useAwesome) {
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

  void _showWarningSnackBar(String message) {
    final settingsState = context.read<SettingsBloc>().state;
    final useAwesome = settingsState is SettingsLoaded
        ? settingsState.settings.useAwesomeSnackbar
        : true;

    if (useAwesome) {
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
