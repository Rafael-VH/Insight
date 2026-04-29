import 'package:flutter/material.dart';
import 'package:insight/features/parser/utils/mlbb_parser.dart';
import 'package:insight/features/parser/utils/mlbb_validator.dart';
import 'package:insight/features/parser/domain/entities/game_mode.dart';
import 'package:insight/features/parser/domain/entities/player_performance.dart';
import 'package:insight/features/upload/domain/entities/game_session.dart';
import 'package:insight/features/upload/domain/entities/upload_mode.dart';
import 'package:insight/features/parser/presentation/utils/game_mode_extensions.dart';

/// Resultado del procesamiento de OCR con validación
class OcrProcessingResult {
  final PlayerPerformance? stats;
  final ValidationResult? validation;
  final String? imagePath;
  final List<String> extractionLog;
  final GameMode? processedMode;

  const OcrProcessingResult({
    required this.stats,
    required this.validation,
    required this.imagePath,
    required this.extractionLog,
    this.processedMode,
  });

  bool get hasValidStats => stats != null && validation != null;
  bool get isValid => validation?.isValid ?? false;
}

/// Controlador para manejar la lógica de estado de StatsUploadScreen
class StatsUploadController extends ChangeNotifier {
  final StatsUploadType uploadType;

  late final Map<GameMode, String?> _uploadedImages;
  late final Map<GameMode, PlayerPerformance?> _parsedStats;
  late final Map<GameMode, ValidationResult?> _validationResults;
  late final Map<GameMode, bool> _isProcessing;
  late final Map<GameMode, List<String>> _extractionLogs;

  GameMode? _currentProcessingMode;
  GameMode? _lastProcessedMode;

  bool _isDisposed = false;

  StatsUploadController({required this.uploadType}) {
    _initializeState();
  }

  Map<GameMode, String?> get uploadedImages => Map.unmodifiable(_uploadedImages);
  Map<GameMode, PlayerPerformance?> get parsedStats => Map.unmodifiable(_parsedStats);
  Map<GameMode, ValidationResult?> get validationResults => Map.unmodifiable(_validationResults);
  Map<GameMode, bool> get isProcessing => Map.unmodifiable(_isProcessing);
  GameMode? get currentProcessingMode => _currentProcessingMode;
  GameMode? get lastProcessedMode => _lastProcessedMode;

  List<GameMode> get availableModes {
    if (uploadType == StatsUploadType.total) {
      return [GameMode.total];
    }
    return GameMode.values.where((mode) => mode != GameMode.total).toList();
  }

  bool get hasAnyParsedStats {
    return _parsedStats.values.any((stats) => stats != null);
  }

  ValidationResult? getValidationResult(GameMode mode) {
    return _validationResults[mode];
  }

  List<String> getExtractionLog(GameMode mode) {
    return List.unmodifiable(_extractionLogs[mode] ?? []);
  }

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

  void startProcessing(GameMode mode) {
    _assertNotDisposed();
    if (!availableModes.contains(mode)) {
      throw ArgumentError('Mode $mode not available for this upload type');
    }

    _currentProcessingMode = mode;
    _lastProcessedMode = mode;
    _isProcessing[mode] = true;

    notifyListeners();
  }

  OcrProcessingResult handleOcrSuccessWithDiagnostics(String text, String? imagePath) {
    _assertNotDisposed();

    final mode = _currentProcessingMode ?? _lastProcessedMode;

    if (mode == null) {
      return const OcrProcessingResult(
        stats: null,
        validation: null,
        imagePath: null,
        extractionLog: ['ERROR: No se pudo determinar el modo de procesamiento'],
        processedMode: null,
      );
    }

    try {
      StatsParser.clearLog();

      final parseResult = StatsParser.parseStatsWithDiagnostics(text, mode);

      ValidationResult? validation;
      if (parseResult.stats != null) {
        validation = StatsValidator.validate(parseResult.stats!);
      }

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
        processedMode: mode,
      );
    } catch (e) {
      _isProcessing[mode] = false;
      _currentProcessingMode = null;

      notifyListeners();

      return OcrProcessingResult(
        stats: null,
        validation: null,
        imagePath: null,
        extractionLog: ['ERROR: ${e.toString()}'],
        processedMode: mode,
      );
    }
  }

  void handleOcrSuccess(String text, String? imagePath) {
    handleOcrSuccessWithDiagnostics(text, imagePath);
  }

  void handleOcrError() {
    _assertNotDisposed();

    final mode = _currentProcessingMode ?? _lastProcessedMode;
    if (mode == null) return;

    _isProcessing[mode] = false;
    _currentProcessingMode = null;

    notifyListeners();
  }

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

    if (_lastProcessedMode == mode) {
      _lastProcessedMode = null;
    }

    notifyListeners();
  }

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

  bool hasInvalidStats() {
    for (final entry in _validationResults.entries) {
      if (entry.value != null && !entry.value!.isValid) {
        return true;
      }
    }
    return false;
  }

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

  void _assertNotDisposed() {
    if (_isDisposed) {
      throw StateError('StatsUploadController has been disposed');
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;

    _uploadedImages.clear();
    _parsedStats.clear();
    _validationResults.clear();
    _isProcessing.clear();
    _extractionLogs.clear();
    _currentProcessingMode = null;
    _lastProcessedMode = null;

    super.dispose();
  }
}
