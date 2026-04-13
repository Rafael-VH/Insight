import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insight/features/parser/domain/entities/game_mode.dart';
import 'package:insight/features/ocr/domain/entities/ocr_image_source.dart';
import 'package:insight/features/upload/domain/entities/upload_mode.dart';
import 'package:insight/features/ocr/presentation/bloc/ocr_bloc.dart';
import 'package:insight/features/ocr/presentation/bloc/ocr_event.dart';
import 'package:insight/features/ocr/presentation/bloc/ocr_state.dart';
import 'package:insight/features/upload/presentation/bloc/upload_bloc.dart';
import 'package:insight/features/upload/presentation/bloc/upload_state.dart';
import 'package:insight/features/upload/presentation/controllers/upload_controller.dart';

import 'widgets/upload_app_bar.dart';
import 'widgets/upload_mode_card.dart';
import 'widgets/upload_state_handler_mixin.dart';
import 'widgets/upload_parsed_results.dart';
import 'widgets/upload_validation_summary_dialog.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key, required this.uploadType});

  final StatsUploadType uploadType;

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> with UploadStateHandlerMixin {
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
  set currentValidatingMode(GameMode? value) => setState(() => _currentValidatingMode = value);

  /// 0 = sin nada · 1 = imagen(s) cargada(s) · 2 = stats extraídas
  int get _currentStep {
    if (_controller.hasAnyParsedStats) return 2;
    final anyImage = _controller.availableModes.any((m) => _controller.uploadedImages[m] != null);
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          body: ListenableBuilder(listenable: _controller, builder: (_, __) => _buildBody()),
          // ── FAB de guardar ────────────────────────────────────
          floatingActionButton: ListenableBuilder(
            listenable: _controller,
            builder: (_, __) {
              if (!_controller.hasAnyParsedStats) return const SizedBox.shrink();
              return _SaveFab(
                isSaving: _isSaving,
                hasInvalidStats: _controller.hasInvalidStats(),
                onSave: saveStats,
                colorScheme: colorScheme,
                isDark: isDark,
              );
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        ),
      ),
    );
  }

  Widget _buildBody() {
    // Padding inferior extra cuando el FAB está visible, para que el
    // contenido no quede debajo del botón flotante.
    final bottomPadding = _controller.hasAnyParsedStats ? 88.0 : 24.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
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
}

// ══════════════════════════════════════════════════════════════════
// FAB de guardar
// ══════════════════════════════════════════════════════════════════

class _SaveFab extends StatelessWidget {
  const _SaveFab({
    required this.isSaving,
    required this.hasInvalidStats,
    required this.onSave,
    required this.colorScheme,
    required this.isDark,
  });

  final bool isSaving;
  final bool hasInvalidStats;
  final VoidCallback onSave;
  final ColorScheme colorScheme;
  final bool isDark;

  Color get _bgColor {
    if (isSaving) return colorScheme.onSurface.withValues(alpha: 0.12);
    if (hasInvalidStats) return Colors.orange;
    return const Color(0xFF059669);
  }

  String get _label {
    if (isSaving) return 'Guardando…';
    if (hasInvalidStats) return 'Guardar con datos incompletos';
    return 'Guardar estadísticas';
  }

  IconData get _icon {
    if (hasInvalidStats) return Icons.save_outlined;
    return Icons.check_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Margen horizontal para que el FAB no llegue a los bordes
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSaving
              ? null
              : [
                  BoxShadow(
                    color: _bgColor.withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: isSaving ? null : onSave,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSaving)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    )
                  else
                    Icon(_icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSaving ? colorScheme.onSurface.withValues(alpha: 0.4) : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
