import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:insight/features/stats/domain/entities/game_mode.dart';
import 'package:insight/features/stats/domain/entities/image_source_type.dart';
import 'package:insight/features/stats/domain/entities/stats_upload_type.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_bloc.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_state.dart';
import 'package:insight/features/stats/presentation/bloc/ocr/ocr_bloc.dart';
import 'package:insight/features/stats/presentation/bloc/ocr/ocr_event.dart';
import 'package:insight/features/stats/presentation/bloc/ocr/ocr_state.dart';
import 'package:insight/features/stats/presentation/controllers/stats_upload_controller.dart';

// Widgets locales de esta pantalla
import 'widgets/upload_app_bar.dart';
import 'widgets/upload_image_card_with_overlay.dart';
import 'widgets/upload_save_button.dart';
import 'widgets/upload_state_handler_mixin.dart';
import 'widgets/upload_stats_section.dart';
import 'widgets/upload_validation_summary_dialog.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key, required this.uploadType});

  final StatsUploadType uploadType;

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with UploadStateHandlerMixin {
  late final StatsUploadController _controller;

  // Campos backing — no llevan @override, son campos privados del State
  bool _isSaving = false;
  GameMode? _currentValidatingMode;

  // Implementaciones de la interfaz del mixin
  @override
  StatsUploadController get uploadController => _controller;

  @override
  bool get isSaving => _isSaving;

  @override
  set isSaving(bool value) => setState(() => _isSaving = value);

  @override
  GameMode? get currentValidatingMode => _currentValidatingMode;

  @override
  set currentValidatingMode(GameMode? value) =>
      setState(() => _currentValidatingMode = value);

  Timer? _saveTimeoutTimer;

  // ==================== LIFECYCLE ====================

  @override
  void initState() {
    super.initState();
    _controller = StatsUploadController(uploadType: widget.uploadType);
  }

  @override
  void dispose() {
    _saveTimeoutTimer?.cancel();
    _controller.dispose();
    _currentValidatingMode = null;
    super.dispose();
  }

  // ==================== ACCIONES ====================

  void _onImageUploadPressed(ImageSourceType source, GameMode mode) {
    _controller.startProcessing(mode);
    context.read<OcrBloc>().add(ProcessImageEvent(source));
  }

  void _showValidationSummary() {
    UploadValidationSummaryDialog.show(
      context: context,
      availableModes: _controller.availableModes,
      getValidation: _controller.getValidationResult,
    );
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return BlocListener<OcrBloc, OcrState>(
      listener: (_, state) => handleOcrState(state),
      child: BlocListener<StatsBloc, StatsState>(
        listener: (_, state) => handleStatsState(state),
        child: Scaffold(
          appBar: UploadAppBar(
            title: widget.uploadType.appBarTitle,
            hasStats: _controller.hasAnyParsedStats,
            onShowSummary: _showValidationSummary,
          ),
          body: ListenableBuilder(
            listenable: _controller,
            builder: (_, _) => _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._buildImageCards(),
          const SizedBox(height: 16),
          if (_controller.hasAnyParsedStats) ...[
            UploadStatsSection(
              parsedStats: _controller.parsedStats,
              hasInvalidStats: _controller.hasInvalidStats(),
            ),
            const SizedBox(height: 16),
            UploadSaveButton(
              isSaving: _isSaving,
              hasInvalidStats: _controller.hasInvalidStats(),
              onSave: saveStats,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildImageCards() {
    return _controller.availableModes.map((mode) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: UploadImageCardWithOverlay(
          key: ValueKey(mode),
          mode: mode,
          imagePath: _controller.uploadedImages[mode],
          isProcessing: _controller.isProcessing[mode] ?? false,
          validation: _controller.validationResults[mode],
          onUploadPressed: (source) => _onImageUploadPressed(source, mode),
          onValidationBadgeTap: () {
            final validation = _controller.validationResults[mode];
            if (validation != null) {
              showValidationDialog(validation, mode);
            }
          },
        ),
      );
    }).toList();
  }
}
