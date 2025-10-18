import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
//
import 'package:insight/core/utils/stats_validator.dart';
//
import 'package:insight/stats/domain/entities/game_mode.dart';
import 'package:insight/stats/domain/entities/image_source_type.dart';
import 'package:insight/stats/domain/entities/stats_upload_type.dart';
//
import 'package:insight/stats/presentation/bloc/ml_stats_bloc.dart';
import 'package:insight/stats/presentation/bloc/ml_stats_event.dart';
import 'package:insight/stats/presentation/bloc/ml_stats_state.dart';
import 'package:insight/stats/presentation/bloc/ocr_bloc.dart';
import 'package:insight/stats/presentation/bloc/ocr_event.dart';
import 'package:insight/stats/presentation/bloc/ocr_state.dart';
//
import 'package:insight/stats/presentation/controllers/stats_upload_controller.dart';
//
import 'package:insight/stats/presentation/pages/Upload/widget/image_upload_card.dart';
//
import 'package:insight/stats/presentation/widgets/save_stats_dialog.dart';
import 'package:insight/stats/presentation/widgets/stats_verification_widget.dart';
import 'package:insight/stats/presentation/widgets/validation_result_dialog.dart';

class StatsUploadPage extends StatefulWidget {
  const StatsUploadPage({super.key, required this.uploadType});

  final StatsUploadType uploadType;

  @override
  State<StatsUploadPage> createState() => _StatsUploadPageState();
}

class _StatsUploadPageState extends State<StatsUploadPage> {
  late final StatsUploadController _controller;
  bool _isSaving = false;

  // NUEVO: Variable para rastrear el modo actual en validación
  GameMode? _currentValidatingMode;

  @override
  void initState() {
    super.initState();
    _controller = StatsUploadController(uploadType: widget.uploadType);
  }

  @override
  void dispose() {
    _controller.dispose();
    _currentValidatingMode = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OcrBloc, OcrState>(
      listener: _handleOcrState,
      child: BlocListener<MLStatsBloc, MLStatsState>(
        listener: _handleMlStatsState,
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            return Scaffold(
              appBar: AppBar(
                title: Text(widget.uploadType.appBarTitle),
                actions: [
                  if (_controller.hasAnyParsedStats)
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: _showValidationSummary,
                      tooltip: 'Ver resumen de validación',
                    ),
                ],
              ),
              body: SingleChildScrollView(
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
              ),
            );
          },
        ),
      ),
    );
  }

  /// Maneja los eventos de OCR (captura de imágenes)
  void _handleOcrState(BuildContext context, OcrState state) {
    if (state is OcrSuccess) {
      // Procesar con diagnóstico completo
      final result = _controller.handleOcrSuccessWithDiagnostics(
        state.result.recognizedText,
        state.result.imagePath,
      );

      final mode = _controller.currentProcessingMode;

      if (result.hasValidStats && result.validation != null) {
        // MEJORADO: Guardar el modo actual para validación
        _currentValidatingMode = mode;
        // Mostrar diálogo de validación
        _showValidationDialog(result.validation!, mode);
      } else {
        _showErrorSnackBar(
          'No se pudieron extraer las estadísticas. Por favor, verifica la imagen.',
        );
        _showExtractionLogDialog(result.extractionLog);
      }
    } else if (state is OcrError) {
      _controller.handleOcrError();
      _showErrorSnackBar('Error: ${state.message}');
    }
  }

  /// Maneja los eventos de guardación de estadísticas
  void _handleMlStatsState(BuildContext context, MLStatsState state) {
    if (state is MLStatsSaving) {
      print('💾 Estado: Guardando...');
      setState(() => _isSaving = true);
    } else if (state is MLStatsSaved) {
      print('✅ Estado: Guardado exitoso');
      setState(() => _isSaving = false);

      // Cerrar diálogo de carga si está abierto
      if (mounted && Navigator.canPop(context)) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (e) {
          print('⚠ No hay diálogo para cerrar');
        }
      }

      // Mostrar diálogo de éxito
      SaveStatsDialog.showSuccess(
        context,
        message: state.message,
        onClose: () {
          if (mounted) {
            print('🏠 Volviendo a pantalla principal...');

            // Cerrar diálogo de éxito
            Navigator.of(context).pop();

            // CRÍTICO: Recargar historial antes de volver
            context.read<MLStatsBloc>().add(LoadAllStatsCollectionsEvent());

            // Esperar un momento y volver
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                // Volver a la pantalla principal (cerrar todas las pantallas de upload)
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            });
          }
        },
      );
    } else if (state is MLStatsError) {
      print('❌ Estado: Error - ${state.message}');
      setState(() => _isSaving = false);

      // Cerrar diálogo de carga si está abierto
      if (mounted && Navigator.canPop(context)) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (e) {
          print('⚠ No hay diálogo para cerrar');
        }
      }

      // Mostrar diálogo de error
      SaveStatsDialog.showError(
        context,
        title: 'Error al Guardar',
        message: state.message,
        errorDetails: state.errorDetails,
        onRetry: _isSaving ? null : _saveStats,
      );
    }
  }

  /// Valida y guarda las estadísticas
  Future<void> _saveStats() async {
    if (_isSaving) {
      _showWarningSnackBar('Ya se está guardando...');
      return;
    }

    setState(() => _isSaving = true);

    final collection = _controller.createCollection();

    if (!collection.hasAnyStats) {
      setState(() => _isSaving = false);
      SaveStatsDialog.showError(
        context,
        title: 'Sin Estadísticas',
        message: 'Carga al menos una estadística.',
      );
      return;
    }

    SaveStatsDialog.showSaving(context);

    // Esperar que el diálogo se muestre completamente
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      context.read<MLStatsBloc>().add(SaveStatsCollectionEvent(collection));
    }
  }

  /// Construye las tarjetas de carga de imágenes
  List<Widget> _buildImageUploadCards() {
    return _controller.availableModes.map((mode) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Stack(
          children: [
            ImageUploadCard(
              key: ValueKey(mode),
              gameMode: mode,
              imagePath: _controller.uploadedImages[mode],
              isProcessing: _controller.isProcessing[mode] ?? false,
              onUploadPressed: (source) => _onImageUploadPressed(source, mode),
            ),
            // Badge de validación
            if (_controller.validationResults[mode] != null)
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

  /// Construye el badge de validación
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

    return GestureDetector(
      onTap: () => _showValidationDialog(validation, mode),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  /// Construye la sección de estadísticas extraídas
  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Estadísticas extraídas:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_controller.hasInvalidStats())
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: Colors.orange[900],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Datos incompletos',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[900],
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

  /// Construye los widgets de verificación de estadísticas
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

  /// Construye el botón de guardar
  Widget _buildSaveButton() {
    final hasInvalid = _controller.hasInvalidStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasInvalid)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Algunos datos están incompletos. Puedes guardar de todos modos o reintentar la captura.',
                    style: TextStyle(fontSize: 13, color: Colors.orange[900]),
                  ),
                ),
              ],
            ),
          ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveStats,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isSaving
                ? Colors.grey
                : hasInvalid
                ? Colors.orange
                : const Color(0xFF059669),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            disabledBackgroundColor: Colors.grey,
          ),
          child: _isSaving
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Guardando...'),
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

  /// Maneja la presión en los botones de carga de imagen
  void _onImageUploadPressed(ImageSourceType source, GameMode mode) {
    _controller.startProcessing(mode);
    context.read<OcrBloc>().add(ProcessImageEvent(source));
  }

  /// Muestra el diálogo de validación
  void _showValidationDialog(ValidationResult validation, GameMode? mode) {
    // MEJORADO: Guardar el modo si no está guardado
    if (mode != null) {
      _currentValidatingMode = mode;
    }

    ValidationResultDialog.show(
      context: context,
      result: validation,
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

  /// Reintentar captura de imagen
  void _retryImageCapture(GameMode mode) {
    _controller.removeStats(mode);
    _currentValidatingMode = null;
    _showSuccessSnackBar('Por favor, vuelve a capturar la imagen');
  }

  /// Muestra el log de extracción
  void _showExtractionLogDialog(List<String> log) {
    if (log.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log de Extracción'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: log.length,
            itemBuilder: (context, index) {
              final entry = log[index];
              final isError = entry.contains('ERROR') || entry.contains('✗');
              final isSuccess = entry.contains('✓');

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  entry,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: isError
                        ? Colors.red
                        : isSuccess
                        ? Colors.green
                        : Colors.black87,
                  ),
                ),
              );
            },
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

  /// Muestra el resumen de validación
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resumen de Validación'),
        content: SingleChildScrollView(child: Text(buffer.toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Muestra SnackBar de éxito
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Muestra SnackBar de advertencia
  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Muestra SnackBar de error
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
