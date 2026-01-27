import 'package:flutter/material.dart';
import 'package:insight/core/utils/stats_parser.dart';
import 'package:insight/core/utils/stats_validator.dart';
import 'package:insight/features/stats/domain/entities/game_mode.dart';
import 'package:insight/features/stats/domain/entities/player_stats.dart';
import 'package:insight/features/stats/domain/entities/stats_collection.dart';
import 'package:insight/features/stats/domain/entities/stats_upload_type.dart';
import 'package:insight/features/stats/presentation/utils/game_mode_extensions.dart';

/// Resultado del procesamiento de OCR con validación
class OcrProcessingResult {
  final PlayerStats? stats;
  final ValidationResult? validation;
  final String? imagePath;
  final List<String> extractionLog;

  const OcrProcessingResult({
    required this.stats,
    required this.validation,
    required this.imagePath,
    required this.extractionLog,
  });

  bool get hasValidStats => stats != null && validation != null;
  bool get isValid => validation?.isValid ?? false;
}

/// Controlador para manejar la lógica de estado de StatsUploadScreen
class StatsUploadController extends ChangeNotifier {
  final StatsUploadType uploadType;

  // Inicialización lazy para evitar problemas de memoria
  late final Map<GameMode, String?> _uploadedImages;
  late final Map<GameMode, PlayerStats?> _parsedStats;
  late final Map<GameMode, ValidationResult?> _validationResults;
  late final Map<GameMode, bool> _isProcessing;
  late final Map<GameMode, List<String>> _extractionLogs;
  GameMode? _currentProcessingMode;

  // Control de dispose
  bool _isDisposed = false;

  StatsUploadController({required this.uploadType}) {
    _initializeState();
  }

  // Getters
  Map<GameMode, String?> get uploadedImages =>
      Map.unmodifiable(_uploadedImages);
  Map<GameMode, PlayerStats?> get parsedStats => Map.unmodifiable(_parsedStats);
  Map<GameMode, ValidationResult?> get validationResults =>
      Map.unmodifiable(_validationResults);
  Map<GameMode, bool> get isProcessing => Map.unmodifiable(_isProcessing);
  GameMode? get currentProcessingMode => _currentProcessingMode;

  List<GameMode> get availableModes {
    if (uploadType == StatsUploadType.total) {
      return [GameMode.total];
    }
    return GameMode.values.where((mode) => mode != GameMode.total).toList();
  }

  bool get hasAnyParsedStats {
    return _parsedStats.values.any((stats) => stats != null);
  }

  /// Obtiene el resultado de validación para un modo específico
  ValidationResult? getValidationResult(GameMode mode) {
    return _validationResults[mode];
  }

  /// Obtiene el log de extracción para un modo específico
  List<String> getExtractionLog(GameMode mode) {
    return List.unmodifiable(_extractionLogs[mode] ?? []);
  }

  /// Inicialización de estado
  void _initializeState() {
    _uploadedImages = {};
    _parsedStats = {};
    _validationResults = {};
    _isProcessing = {};
    _extractionLogs = {};

    for (final mode in availableModes) {
      _isProcessing[mode] = false;
      _uploadedImages[mode] = null;
      _parsedStats[mode] = null;
      _validationResults[mode] = null;
      _extractionLogs[mode] = [];
    }
  }

  /// Iniciar procesamiento con validación
  void startProcessing(GameMode mode) {
    _assertNotDisposed();
    if (!availableModes.contains(mode)) {
      throw ArgumentError('Mode $mode not available for this upload type');
    }
    _currentProcessingMode = mode;
    _isProcessing[mode] = true;
    notifyListeners();
  }

  /// Procesa el resultado de OCR con diagnóstico completo
  OcrProcessingResult handleOcrSuccessWithDiagnostics(
    String text,
    String? imagePath,
  ) {
    _assertNotDisposed();

    final mode = _currentProcessingMode;
    if (mode == null) {
      return const OcrProcessingResult(
        stats: null,
        validation: null,
        imagePath: null,
        extractionLog: [],
      );
    }

    try {
      // Limpiar logs anteriores
      StatsParser.clearLog();

      // Usar el parser mejorado con diagnóstico
      final parseResult = StatsParser.parseStatsWithDiagnostics(text, mode);

      // Validar las estadísticas si se pudieron extraer
      ValidationResult? validation;
      if (parseResult.stats != null) {
        validation = StatsValidator.validate(parseResult.stats!);
      }

      // Guardar los resultados de forma segura
      _uploadedImages[mode] = imagePath;
      _parsedStats[mode] = parseResult.stats;
      _validationResults[mode] = validation;
      _extractionLogs[mode] = List.from(parseResult.extractionLog);
      _isProcessing[mode] = false;
      _currentProcessingMode = null;

      notifyListeners();

      return OcrProcessingResult(
        stats: parseResult.stats,
        validation: validation,
        imagePath: imagePath,
        extractionLog: parseResult.extractionLog,
      );
    } catch (e) {
      print('Error en handleOcrSuccessWithDiagnostics: $e');
      _isProcessing[mode] = false;
      _currentProcessingMode = null;
      notifyListeners();

      return OcrProcessingResult(
        stats: null,
        validation: null,
        imagePath: null,
        extractionLog: ['ERROR: ${e.toString()}'],
      );
    }
  }

  /// Método legacy para compatibilidad
  void handleOcrSuccess(String text, String? imagePath) {
    handleOcrSuccessWithDiagnostics(text, imagePath);
  }

  /// Manejo de errores de OCR
  void handleOcrError() {
    _assertNotDisposed();

    final mode = _currentProcessingMode;
    if (mode == null) return;

    _isProcessing[mode] = false;
    _currentProcessingMode = null;

    notifyListeners();
  }

  /// Remover estadísticas con limpieza completa
  void removeStats(GameMode mode) {
    _assertNotDisposed();

    _uploadedImages[mode] = null;
    _parsedStats[mode] = null;
    _validationResults[mode] = null;
    _extractionLogs[mode] = [];
    _isProcessing[mode] = false;

    if (_currentProcessingMode == mode) {
      _currentProcessingMode = null;
    }

    notifyListeners();
  }

  /// Crear colección con validación
  StatsCollection createCollection() {
    _assertNotDisposed();

    return StatsCollection(
      totalStats: _parsedStats[GameMode.total],
      rankedStats: _parsedStats[GameMode.ranked],
      classicStats: _parsedStats[GameMode.classic],
      brawlStats: _parsedStats[GameMode.brawl],
      createdAt: DateTime.now(),
    );
  }

  /// Obtener mensaje de éxito personalizado
  String getSuccessMessage(GameMode mode) {
    final validation = _validationResults[mode];
    if (validation == null) {
      return 'Estadísticas extraídas para ${mode.fullDisplayName}';
    }

    if (validation.isValid && validation.warningFields.isEmpty) {
      return '✓ Estadísticas completas extraídas para ${mode.fullDisplayName}';
    } else if (validation.isValid) {
      return '⚠ Estadísticas extraídas para ${mode.fullDisplayName} (con advertencias)';
    } else {
      return '✗ Extracción incompleta para ${mode.fullDisplayName}';
    }
  }

  /// Verifica si hay alguna estadística con validación fallida
  bool hasInvalidStats() {
    for (final entry in _validationResults.entries) {
      if (entry.value != null && !entry.value!.isValid) {
        return true;
      }
    }
    return false;
  }

  /// Obtiene el resumen de todas las validaciones
  String getValidationSummary() {
    final buffer = StringBuffer();
    int totalModes = 0;
    int validModes = 0;

    for (final mode in availableModes) {
      final validation = _validationResults[mode];
      if (validation != null) {
        totalModes++;
        if (validation.isValid) validModes++;
      }
    }

    if (totalModes == 0) {
      return 'No hay estadísticas procesadas';
    }

    buffer.write('$validModes de $totalModes modos válidos');
    return buffer.toString();
  }

  /// Método para verificar si el controlador ha sido liberado
  void _assertNotDisposed() {
    if (_isDisposed) {
      throw StateError('StatsUploadController has been disposed');
    }
  }

  /// Dispose con limpieza completa de memoria
  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;

    // Limpiar mapas
    _uploadedImages.clear();
    _parsedStats.clear();
    _validationResults.clear();
    _isProcessing.clear();
    _extractionLogs.clear();
    _currentProcessingMode = null;

    super.dispose();
  }
}
