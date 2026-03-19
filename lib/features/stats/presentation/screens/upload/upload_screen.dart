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

  // Mantiene el modo actual que está siendo validado - Necesaria para el callback de "Reintentar" en el diálogo de validación
  GameMode? _currentValidatingMode;

  // Timer para debouncing de validaciones - Evitar múltiples validaciones si el usuario carga imágenes rápidamente - Mejora el rendimiento y evita diálogos múltiples
  Timer? _validationDebounceTimer;

  // Timer para timeout de operaciones de guardado - Prevenir que la UI se quede bloqueada si el guardado falla silenciosamente - Mejora la experiencia del usuario detectando cuando el guardado toma demasiado tiempo
  Timer? _saveTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _controller = StatsUploadController(uploadType: widget.uploadType);
  }

  @override
  void dispose() {
    // Limpiar todos los timers antes de dispose - Prevenir memory leaks y callbacks después de que el widget se haya desmontado
    _validationDebounceTimer?.cancel();
    _saveTimeoutTimer?.cancel();

    // Limpiar controller y estado
    _controller.dispose();
    _currentValidatingMode = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usa BlocListener para escuchar estados sin reconstruir - Separar la lógica de side effects (diálogos, navegación) de la UI
    return BlocListener<OcrBloc, OcrState>(
      listener: _handleOcrState,
      child: BlocListener<StatsBloc, StatsState>(
        listener: _handleMlStatsState,
        child: Scaffold(
          //AppBar fuera del ListenableBuilder - El AppBar no depende del controller, no debe reconstruirse - Reduce reconstrucciones innecesarias, mejora rendimiento
          appBar: _buildAppBar(),

          // Solo el body está dentro del ListenableBuilder - Solo reconstruir el contenido que cambia con el controller
          body: ListenableBuilder(
            listenable: _controller,
            builder: (context, child) => _buildBody(),
          ),
        ),
      ),
    );
  }

  // ==================== APP BAR ====================

  // Método extraído para construir AppBar - Mejor organización del código y reutilización - Código más legible y mantenible
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

  // ==================== BODY ====================

  // Método extraído para construir el body - Separar la lógica de construcción de widgets - Código más limpio y testeable
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

  // ==================== OCR STATE HANDLER ====================

  // Escucha cambios en OcrBloc - Centralizar la lógica de respuesta a eventos de OCR
  void _handleOcrState(BuildContext context, OcrState state) {
    // Obtener preferencia del usuario sobre el tipo de diálogos
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

  // Método específico para manejar éxito de OCR - Separar la lógica compleja de manejo de éxito - Código más legible y fácil de debuggear
  void _handleOcrSuccess(
    BuildContext context,
    OcrSuccess state,
    bool useAwesome,
  ) {
    debugPrint('📥 OCR Success - Iniciando procesamiento');

    // Procesar con diagnóstico completo usando el controller
    final result = _controller.handleOcrSuccessWithDiagnostics(
      state.result.recognizedText,
      state.result.imagePath,
    );

    // ✅ Usar el modo del resultado, no del controller
    final mode = result.processedMode;

    if (mode == null) {
      debugPrint('❌ Error: modo de procesamiento es null en el resultado');
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

    debugPrint('✅ Modo procesado: ${mode.fullDisplayName}');

    if (result.hasValidStats && result.validation != null) {
      debugPrint('📊 Estadísticas válidas encontradas');

      // Implementar debouncing para validaciones
      _validationDebounceTimer?.cancel();
      _validationDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          _currentValidatingMode = mode;
          _showValidationDialog(result.validation!, mode);
        }
      });
    } else {
      debugPrint('⚠️ Estadísticas incompletas o inválidas');

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

      // Mostrar log detallado solo si hay información de debugging
      if (result.extractionLog.isNotEmpty) {
        debugPrint(
          '📋 Log de extracción disponible (${result.extractionLog.length} entradas)',
        );
        // Opcional: mostrar automáticamente en modo debug
        // _showExtractionLogDialog(result.extractionLog);
      }
    }
  }

  // Método específico para manejar errores de OCR - Proporcionar mensajes de error contextuales y útiles
  void _handleOcrError(BuildContext context, OcrError state, bool useAwesome) {
    _controller.handleOcrError();

    // Mensajes de error contextuales basados en el tipo de error - Todos los errores mostraban el mismo mensaje genérico - Usuario recibe instrucciones específicas para resolver su problema
    String title = 'Error en OCR';
    String message = state.message;
    String? suggestion;

    // Detectar tipo de error y proporcionar sugerencia específica
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

  // ==================== ML STATS STATE HANDLER ====================

  // Escucha cambios en MLStatsBloc durante el guardado - Coordinar la UI con el proceso de guardado de estadísticas
  void _handleMlStatsState(BuildContext context, StatsState state) {
    final settingsState = context.read<SettingsBloc>().state;
    final useAwesome = settingsState is SettingsLoaded
        ? settingsState.settings.useAwesomeSnackbar
        : true;

    if (state is StatsSaving) {
      _handleSavingState(context, useAwesome);
    } else {
      // SIEMPRE resetear _isSaving en estados finales - Si ocurría un error, _isSaving podía quedar en true - El botón de guardar quedaba deshabilitado permanentemente - Resetear el flag antes de manejar estados específicos
      if (_isSaving) {
        setState(() => _isSaving = false);
        _saveTimeoutTimer?.cancel(); // También cancelar el timeout
      }

      // Manejo separado de estados finales - Código más claro y fácil de mantener
      if (state is StatsSaved) {
        _handleSuccessfulSave(context, state, useAwesome);
      } else if (state is StatsError) {
        _handleSaveError(context, state, useAwesome);
      }
    }
  }

  // Manejo del estado de guardando - Centralizar lógica de inicio de guardado con seguridad
  void _handleSavingState(BuildContext context, bool useAwesome) {
    // No activar múltiples veces si ya está guardando - Múltiples clics pueden causar guardados duplicados - Return temprano si ya está en proceso
    if (_isSaving) return;

    debugPrint('💾 Estado: Guardando...');
    setState(() => _isSaving = true);

    // Timeout de seguridad (30 segundos) - Si el guardado falla silenciosamente, el usuario queda esperando - Timer que detecta si el guardado toma demasiado tiempo - Usuario recibe feedback si algo sale mal
    _saveTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_isSaving && mounted) {
        debugPrint('⏰ Timeout al guardar - operación tomó más de 30 segundos');
        setState(() => _isSaving = false);

        // Cerrar diálogo de loading si existe
        _safelyCloseDialog(context);

        // Mostrar error al usuario
        DialogService.showError(
          context,
          title: 'Tiempo Agotado',
          message: 'El guardado tomó demasiado tiempo',
          errorDetails: 'Por favor, intenta nuevamente',
          useAwesome: useAwesome,
          onRetry: _saveStats, // Permitir reintentar
        );
      }
    });

    // Mostrar diálogo de loading
    DialogService.showLoading(
      context,
      message: 'Guardando estadísticas...',
      useAwesome: useAwesome,
    );
  }

  // Manejo de guardado exitoso - Centralizar y clarificar el flujo después de guardar
  void _handleSuccessfulSave(
    BuildContext context,
    StatsSaved state,
    bool useAwesome,
  ) async {
    // async para poder usar await
    debugPrint('✅ Estado: Guardado exitoso');

    // Cerrar diálogo de forma segura - Navigator.pop() podía fallar si el diálogo ya estaba cerrado - Método dedicado que verifica antes de cerrar
    await _safelyCloseDialog(context);

    // Verificar mounted después de operación asíncrona - Prevenir errores si el usuario navegó durante la operación
    if (!mounted) return;

    // Mostrar mensaje de éxito con callback de navegación
    DialogService.showSuccess(
      context,
      message: state.message,
      useAwesome: useAwesome,
      onClose: () => _navigateBackToHome(context),
    );
  }

  // Manejo de error al guardar - Proporcionar feedback claro y opción de reintentar
  void _handleSaveError(
    BuildContext context,
    StatsError state,
    bool useAwesome,
  ) async {
    // async para await
    debugPrint('❌ Estado: Error - ${state.message}');

    // Cerrar diálogo de loading de forma segura
    await _safelyCloseDialog(context);

    if (!mounted) return;

    // Mostrar error con opción de reintentar (solo si no está guardando)
    DialogService.showError(
      context,
      title: 'Error al Guardar',
      message: state.message,
      errorDetails: state.errorDetails,
      useAwesome: useAwesome,
      onRetry: _isSaving
          ? null
          : _saveStats, // Deshabilitar retry si está guardando
    );
  }

  // Cerrar diálogo de forma segura - Navigator.pop() podía causar crashes en varios escenarios:
  // 1. Diálogo ya cerrado
  // 2. Widget desmontado durante operación asíncrona
  // 3. Contexto inválido después de navegación
  // Verificaciones exhaustivas antes de cerrar
  Future<void> _safelyCloseDialog(BuildContext context) async {
    // Primera verificación: widget debe estar montado
    if (!mounted) return;

    try {
      // Esperar un frame para asegurar que el contexto es válido - Permite que Flutter complete operaciones pendientes
      await Future.delayed(Duration.zero);

      // Segunda verificación después de await
      if (!mounted) return;

      // Solo intentar pop si hay algo que cerrar - Prevenir errores si no hay diálogo abierto
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      // Log silencioso sin afectar UX - No crashear la app si algo sale mal
      debugPrint('⚠️ Error al cerrar diálogo: $e');
    }
  }

  // Navegación segura de vuelta al home - Coordinar correctamente el flujo de navegación y recarga de datos
  void _navigateBackToHome(BuildContext context) {
    // Verificar mounted antes de cualquier operación
    if (!mounted) return;

    debugPrint('🏠 Volviendo a pantalla principal...');

    // Paso 1: Cerrar diálogo de éxito
    Navigator.of(context).pop();

    // Paso 2: Recargar historial ANTES de navegar - Asegurar que el historial muestre los datos actualizados
    context.read<StatsBloc>().add(LoadAllStatsCollectionsEvent());

    // Paso 3: Navegar después de un pequeño delay - Dar tiempo a que el Bloc procese el evento de recarga
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        // popUntil asegura volver al home sin importar la profundidad
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  // ==================== SAVE STATS ====================

  // Inicia el proceso de guardado de estadísticas
  Future<void> _saveStats() async {
    // Evitar múltiples guardados simultáneos - Usuario puede hacer clic múltiples veces en el botón - Return temprano si ya está guardando
    if (_isSaving) {
      _showWarningSnackBar('Ya se está guardando...');
      return;
    }

    // Crear colección desde el controller
    final collection = _controller.createCollection();

    // Verificar que hay al menos una estadística - No intentar guardar colecciones vacías
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

    // Pequeño delay antes de guardar - Dar tiempo a que el diálogo de loading se muestre correctamente - Mejor feedback visual al usuario
    await Future.delayed(const Duration(milliseconds: 100));

    // Verificar mounted después de await
    if (mounted) {
      context.read<StatsBloc>().add(SaveStatsCollectionEvent(collection));
    }
  }

  // ==================== IMAGE UPLOAD CARDS ====================

  // Construye las tarjetas de carga de imágenes para cada modo
  List<Widget> _buildImageUploadCards() {
    return _controller.availableModes.map((mode) {
      final isProcessing = _controller.isProcessing[mode] ?? false;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Stack(
          children: [
            // Tarjeta base de carga de imagen
            ImageUploadCard(
              key: ValueKey(mode), // Key para identificación única
              gameMode: mode,
              imagePath: _controller.uploadedImages[mode],
              isProcessing: isProcessing,
              onUploadPressed: (source) => _onImageUploadPressed(source, mode),
            ),

            // Overlay de procesamiento más visible - Usuario no sabía que el OCR estaba procesando - Overlay oscuro con spinner y texto descriptivo - Feedback visual claro del estado de procesamiento
            if (isProcessing)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: 0.7,
                    ), // Overlay oscuro
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Spinner de loading
                      const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      // Texto principal
                      const Text(
                        'Procesando imagen...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Texto descriptivo específico del modo
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

            // Badge de validación (solo visible cuando no está procesando)
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

  // Badge visual del resultado de validación - Indicador visual rápido del estado de las estadísticas extraídas
  Widget _buildValidationBadge(ValidationResult validation, GameMode mode) {
    // Determinar icono y color según el resultado de validación
    final IconData icon;
    final Color color;

    if (validation.isValid && validation.warningFields.isEmpty) {
      // Extracción perfecta
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (validation.isValid) {
      // Extracción válida pero con advertencias
      icon = Icons.warning;
      color = Colors.orange;
    } else {
      // Extracción incompleta
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
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  // ==================== STATS SECTION ====================

  // Construye la sección que muestra las estadísticas extraídas
  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con indicador de completitud
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Estadísticas extraídas:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // Badge visual de advertencia si hay datos incompletos - Alertar al usuario antes de guardar
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
        // Widgets de verificación para cada estadística
        ..._buildVerificationWidgets(),
      ],
    );
  }

  // Construye widgets de verificación para estadísticas válidas
  List<Widget> _buildVerificationWidgets() {
    return _controller.parsedStats.entries
        .where((entry) => entry.value != null) // Solo estadísticas válidas
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

  // ==================== SAVE BUTTON ====================

  // Construye el botón de guardar con lógica contextual
  Widget _buildSaveButton() {
    final hasInvalid = _controller.hasInvalidStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Banner informativo si hay datos incompletos - Informar al usuario antes de que tome una decisión
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

        // Botón principal de guardar
        ElevatedButton(
          onPressed: _isSaving
              ? null
              : _saveStats, // Deshabilitar si está guardando
          style: ElevatedButton.styleFrom(
            // Cambia según el estado
            backgroundColor: _isSaving
                ? Colors
                      .grey // Gris cuando está guardando
                : hasInvalid
                ? Colors
                      .orange // Naranja si hay advertencias
                : const Color(0xFF059669), // Verde si todo está bien
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            disabledBackgroundColor: Colors.grey,
          ),
          child: _isSaving
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Spinner mientras guarda
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
                  // Cambia según el estado de validación
                  hasInvalid
                      ? 'Guardar con Datos Incompletos'
                      : 'Guardar Estadísticas',
                ),
        ),
      ],
    );
  }

  // ==================== HELPER METHODS ====================

  // Inicia el proceso de carga y procesamiento de imagen
  void _onImageUploadPressed(ImageSourceType source, GameMode mode) {
    _controller.startProcessing(mode); // Actualizar estado del controller
    context.read<OcrBloc>().add(
      ProcessImageEvent(source),
    ); // Disparar evento OCR
  }

  // Muestra el diálogo de validación de resultados
  void _showValidationDialog(ValidationResult validation, GameMode? mode) {
    final settingsState = context.read<SettingsBloc>().state;
    final useAwesome = settingsState is SettingsLoaded
        ? settingsState.settings.useAwesomeSnackbar
        : true;

    // Actualizar modo actual si se proporciona
    if (mode != null) {
      _currentValidatingMode = mode;
    }

    // Mostrar diálogo con callbacks para acciones
    ValidationResultDialog.show(
      context: context,
      result: validation,
      useAwesome: useAwesome,
      onRetry: () {
        // Callback de reintentar: solo si hay modo válido
        if (_currentValidatingMode != null) {
          _retryImageCapture(_currentValidatingMode!);
        }
      },
      onAccept: () {
        // Callback de aceptar: mostrar mensaje apropiado
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

  // Reinicia el proceso de captura de imagen para un modo específico
  void _retryImageCapture(GameMode mode) {
    _controller.removeStats(mode); // Limpiar datos previos
    _currentValidatingMode = null; // Resetear modo actual
    _showSuccessSnackBar('Por favor, vuelve a capturar la imagen');
  }

  // Muestra el log técnico de extracción (para debugging)
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
              // Colorear según tipo de mensaje
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

  // Muestra un resumen de todas las validaciones
  void _showValidationSummary() {
    final buffer = StringBuffer();
    buffer.writeln('Resumen de Validación\n');

    // Construir resumen para cada modo
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

  // ==================== SNACKBARS ====================

  // Muestra mensaje de éxito - Feedback positivo al usuario
  void _showSuccessSnackBar(String message) {
    final settingsState = context.read<SettingsBloc>().state;
    final useAwesome = settingsState is SettingsLoaded
        ? settingsState.settings.useAwesomeSnackbar
        : true;

    if (useAwesome) {
      // Usar estilo Awesome si está habilitado
      DialogService.showSuccess(context, message: message, useAwesome: true);
    } else {
      // Usar SnackBar estándar
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

  // Muestra mensaje de advertencia - Alertar al usuario sobre situaciones que requieren atención
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
