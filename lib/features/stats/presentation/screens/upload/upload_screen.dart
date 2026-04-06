import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/stats/domain/entities/game_mode.dart';
import 'package:insight/features/stats/domain/entities/image_source_type.dart';
import 'package:insight/features/stats/domain/entities/stats_upload_type.dart';
import 'package:insight/features/stats/presentation/bloc/ocr/ocr_bloc.dart';
import 'package:insight/features/stats/presentation/bloc/ocr/ocr_event.dart';
import 'package:insight/features/stats/presentation/bloc/ocr/ocr_state.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_bloc.dart';
import 'package:insight/features/stats/presentation/bloc/stats/stats_state.dart';
import 'package:insight/features/stats/presentation/controllers/stats_upload_controller.dart';

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

  bool _isSaving = false;
  GameMode? _currentValidatingMode;
  Timer? _saveTimeoutTimer;

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

  // ── Paso actual de la barra de progreso ───────────────────────
  // 0 = sin nada · 1 = imagen(s) cargada(s) · 2 = stats extraídas
  int get _currentStep {
    if (_controller.hasAnyParsedStats) return 2;
    final anyImage = _controller.availableModes.any(
      (m) => _controller.uploadedImages[m] != null,
    );
    if (anyImage) return 1;
    return 0;
  }

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

  // ── Acciones ──────────────────────────────────────────────────

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

  // ── Build ─────────────────────────────────────────────────────

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
            completedSteps: _currentStep,
            onShowSummary: _showValidationSummary,
          ),
          body: ListenableBuilder(
            listenable: _controller,
            builder: (_, __) => _buildBody(),
          ),
          // ── Botón de guardar fijo en el bottom ────────────
          bottomNavigationBar: _controller.hasAnyParsedStats
              ? _buildBottomBar()
              : null,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Tarjetas de imagen por modo ───────────────────
          ..._buildImageCards(),

          // ── Estadísticas extraídas ────────────────────────
          if (_controller.hasAnyParsedStats) ...[
            const SizedBox(height: 20),
            UploadStatsSection(
              parsedStats: _controller.parsedStats,
              hasInvalidStats: _controller.hasInvalidStats(),
            ),
            // Espacio para el bottomBar
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildImageCards() {
    return _controller.availableModes.asMap().entries.map((entry) {
      final mode = entry.value;
      final isLast = entry.key == _controller.availableModes.length - 1;

      return Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
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

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
        ),
        child: UploadSaveButton(
          isSaving: _isSaving,
          hasInvalidStats: _controller.hasInvalidStats(),
          onSave: saveStats,
        ),
      ),
    );
  }
}
