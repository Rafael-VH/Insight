import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/stats/domain/entities/game_mode.dart';
import 'package:insight/stats/domain/entities/image_source_type.dart';
import 'package:insight/stats/domain/entities/stats_upload_type.dart';
import 'package:insight/stats/presentation/bloc/ml_stats_bloc.dart';
import 'package:insight/stats/presentation/bloc/ml_stats_event.dart';
import 'package:insight/stats/presentation/bloc/ocr_bloc.dart';
import 'package:insight/stats/presentation/bloc/ocr_event.dart';
import 'package:insight/stats/presentation/bloc/ocr_state.dart';
import 'package:insight/stats/presentation/controllers/stats_upload_controller.dart';
import 'package:insight/stats/presentation/widgets/image_upload_card.dart';
import 'package:insight/stats/presentation/widgets/stats_verification_widget.dart';

class StatsUploadScreen extends StatefulWidget {
  const StatsUploadScreen({super.key, required this.uploadType});

  final StatsUploadType uploadType;

  @override
  State<StatsUploadScreen> createState() => _StatsUploadScreenState();
}

class _StatsUploadScreenState extends State<StatsUploadScreen> {
  late final StatsUploadController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StatsUploadController(uploadType: widget.uploadType);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OcrBloc, OcrState>(
      listener: _handleOcrState,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.uploadType.appBarTitle)),
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
    );
  }

  void _handleOcrState(BuildContext context, OcrState state) {
    if (state is OcrSuccess) {
      _controller.handleOcrSuccess(
        state.result.recognizedText,
        state.result.imagePath,
      );

      final mode = _controller.currentProcessingMode;
      if (mode != null && _controller.parsedStats[mode] != null) {
        _showSuccessSnackBar(_controller.getSuccessMessage(mode));
      } else {
        _showErrorSnackBar(
          'No se pudieron extraer las estadísticas. Verifica la imagen.',
        );
      }
    } else if (state is OcrError) {
      _controller.handleOcrError();
      _showErrorSnackBar('Error: ${state.message}');
    } else if (state is OcrLoading) {
      // El controller ya maneja el estado de loading
    }
  }

  List<Widget> _buildImageUploadCards() {
    return _controller.availableModes.map((mode) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ImageUploadCard(
          key: ValueKey(mode),
          gameMode: mode,
          imagePath: _controller.uploadedImages[mode],
          isProcessing: _controller.isProcessing[mode] ?? false,
          onUploadPressed: (source) => _onImageUploadPressed(source, mode),
        ),
      );
    }).toList();
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estadísticas extraídas:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    return ElevatedButton(
      onPressed: _saveStats,
      child: const Text('Guardar Estadísticas'),
    );
  }

  void _onImageUploadPressed(ImageSourceType source, GameMode mode) {
    _controller.startProcessing(mode);
    context.read<OcrBloc>().add(ProcessImageEvent(source));
  }

  void _saveStats() {
    final collection = _controller.createCollection();
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
}
