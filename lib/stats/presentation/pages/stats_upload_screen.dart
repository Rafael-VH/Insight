import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/core/utils/stats_parser.dart';
import 'package:insight/stats/domain/entities/game_mode.dart';
import 'package:insight/stats/domain/entities/image_source_type.dart';
import 'package:insight/stats/domain/entities/player_stats.dart';
import 'package:insight/stats/domain/entities/stats_collection.dart';
import 'package:insight/stats/domain/entities/stats_upload_type.dart';
import 'package:insight/stats/presentation/bloc/ml_stats_bloc.dart';
import 'package:insight/stats/presentation/bloc/ml_stats_event.dart';
import 'package:insight/stats/presentation/bloc/ocr_bloc.dart';
import 'package:insight/stats/presentation/bloc/ocr_event.dart';
import 'package:insight/stats/presentation/bloc/ocr_state.dart';
import 'package:insight/stats/presentation/widgets/image_upload_card.dart';
import 'package:insight/stats/presentation/widgets/stats_verification_widget.dart';

class StatsUploadScreen extends StatefulWidget {
  const StatsUploadScreen({super.key, required this.uploadType});

  final StatsUploadType uploadType;

  @override
  State<StatsUploadScreen> createState() => _StatsUploadScreenState();
}

class _StatsUploadScreenState extends State<StatsUploadScreen> {
  Map<GameMode, String?> uploadedImages = {};
  Map<GameMode, PlayerStats?> parsedStats = {};
  Map<GameMode, bool> isProcessing = {};

  GameMode? _currentProcessingMode;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    if (widget.uploadType == StatsUploadType.total) {
      isProcessing[GameMode.total] = false;
      uploadedImages[GameMode.total] = null;
    } else {
      isProcessing[GameMode.ranked] = false;
      isProcessing[GameMode.classic] = false;
      isProcessing[GameMode.brawl] = false;
      uploadedImages[GameMode.ranked] = null;
      uploadedImages[GameMode.classic] = null;
      uploadedImages[GameMode.brawl] = null;
    }
  }

  void _onImageUploadPressed(ImageSourceType source, GameMode mode) {
    setState(() {
      _currentProcessingMode = mode;
    });
    context.read<OcrBloc>().add(ProcessImageEvent(source));
  }

  void _handleOcrSuccess(String text) {
    final mode = _currentProcessingMode;
    if (mode == null) return;

    final stats = StatsParser.parseStats(text, mode);

    setState(() {
      final imagePath = context.read<OcrBloc>().state is OcrSuccess
          ? (context.read<OcrBloc>().state as OcrSuccess).result.imagePath
          : null;
      uploadedImages[mode] = imagePath;
      parsedStats[mode] = stats;
      isProcessing[mode] = false;
    });

    _currentProcessingMode = null;

    if (stats != null) {
      _showSuccessSnackBar(
        'Estadísticas extraídas correctamente para ${mode.displayName}',
      );
    } else {
      _showErrorSnackBar(
        'No se pudieron extraer las estadísticas. Verifica la imagen.',
      );
    }
  }

  void _handleOcrError(String message) {
    setState(() {
      isProcessing[_currentProcessingMode!] = false;
    });
    _currentProcessingMode = null;
    _showErrorSnackBar('Error: $message');
  }

  bool _hasAnyParsedStats() {
    return parsedStats.values.any((stats) => stats != null);
  }

  void _saveStats() {
    // Crear la colección de estadísticas
    final collection = StatsCollection(
      totalStats: parsedStats[GameMode.total],
      rankedStats: parsedStats[GameMode.ranked],
      classicStats: parsedStats[GameMode.classic],
      brawlStats: parsedStats[GameMode.brawl],
      createdAt: DateTime.now(),
    );

    // Usar el bloc para guardar
    context.read<MLStatsBloc>().add(SaveStatsCollectionEvent(collection));
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Widget> _buildImageUploadCards() {
    if (widget.uploadType == StatsUploadType.total) {
      return [
        ImageUploadCard(
          gameMode: GameMode.total,
          imagePath: uploadedImages[GameMode.total],
          isProcessing: isProcessing[GameMode.total]!,
          onUploadPressed: (source) =>
              _onImageUploadPressed(source, GameMode.total),
        ),
      ];
    } else {
      return GameMode.values
          .where((mode) => mode != GameMode.total)
          .map(
            (mode) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ImageUploadCard(
                key: ValueKey(mode),
                gameMode: mode,
                imagePath: uploadedImages[mode],
                isProcessing: isProcessing[mode]!,
                onUploadPressed: (source) =>
                    _onImageUploadPressed(source, mode),
              ),
            ),
          )
          .toList();
    }
  }

  List<Widget> _buildVerificationWidgets() {
    return parsedStats.entries.where((entry) => entry.value != null).map((
      entry,
    ) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: StatsVerificationWidget(
          gameMode: entry.key,
          stats: entry.value!,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OcrBloc, OcrState>(
      listener: (context, state) {
        if (state is OcrSuccess) {
          _handleOcrSuccess(state.result.recognizedText);
        } else if (state is OcrError) {
          _handleOcrError(state.message);
        } else if (state is OcrLoading) {
          setState(() {
            isProcessing[_currentProcessingMode!] = true;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.uploadType.appBarTitle)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._buildImageUploadCards(),
              const SizedBox(height: 16),
              if (_hasAnyParsedStats()) ...[
                const Text(
                  'Estadísticas extraídas:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._buildVerificationWidgets(),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveStats,
                  child: const Text('Guardar Estadísticas'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
