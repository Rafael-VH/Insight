import 'package:flutter/material.dart';
import 'package:insight/core/utils/stats_parser.dart';
import 'package:insight/stats/domain/entities/game_mode.dart';
import 'package:insight/stats/domain/entities/player_stats.dart';
import 'package:insight/stats/domain/entities/stats_collection.dart';
import 'package:insight/stats/domain/entities/stats_upload_type.dart';
import 'package:insight/stats/presentation/utils/game_mode_extensions.dart';

/// Controlador para manejar la lógica de estado de StatsUploadScreen
class StatsUploadController extends ChangeNotifier {
  final StatsUploadType uploadType;

  StatsUploadController({required this.uploadType}) {
    _initializeState();
  }

  // Estado
  final Map<GameMode, String?> _uploadedImages = {};
  final Map<GameMode, PlayerStats?> _parsedStats = {};
  final Map<GameMode, bool> _isProcessing = {};
  GameMode? _currentProcessingMode;

  // Getters
  Map<GameMode, String?> get uploadedImages =>
      Map.unmodifiable(_uploadedImages);
  Map<GameMode, PlayerStats?> get parsedStats => Map.unmodifiable(_parsedStats);
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

  void _initializeState() {
    for (final mode in availableModes) {
      _isProcessing[mode] = false;
      _uploadedImages[mode] = null;
      _parsedStats[mode] = null;
    }
  }

  void startProcessing(GameMode mode) {
    _currentProcessingMode = mode;
    _isProcessing[mode] = true;
    notifyListeners();
  }

  void handleOcrSuccess(String text, String? imagePath) {
    final mode = _currentProcessingMode;
    if (mode == null) return;

    final stats = StatsParser.parseStats(text, mode);

    _uploadedImages[mode] = imagePath;
    _parsedStats[mode] = stats;
    _isProcessing[mode] = false;
    _currentProcessingMode = null;

    notifyListeners();
  }

  void handleOcrError() {
    final mode = _currentProcessingMode;
    if (mode == null) return;

    _isProcessing[mode] = false;
    _currentProcessingMode = null;

    notifyListeners();
  }

  void removeStats(GameMode mode) {
    _uploadedImages[mode] = null;
    _parsedStats[mode] = null;
    _isProcessing[mode] = false;

    if (_currentProcessingMode == mode) {
      _currentProcessingMode = null;
    }

    notifyListeners();
  }

  StatsCollection createCollection() {
    return StatsCollection(
      totalStats: _parsedStats[GameMode.total],
      rankedStats: _parsedStats[GameMode.ranked],
      classicStats: _parsedStats[GameMode.classic],
      brawlStats: _parsedStats[GameMode.brawl],
      createdAt: DateTime.now(),
    );
  }

  String getSuccessMessage(GameMode mode) {
    return 'Estadísticas extraídas correctamente para ${mode.fullDisplayName}';
  }

  @override
  void dispose() {
    super.dispose();
  }
}
