import 'package:flutter/material.dart';
import 'package:insight/core/utils/stats_validator.dart';
import 'package:insight/features/stats/domain/entities/game_mode.dart';
import 'package:insight/features/stats/domain/entities/image_source_type.dart';
import 'package:insight/features/stats/presentation/utils/game_mode_extensions.dart';
import 'package:insight/features/stats/presentation/widgets/image_upload_card.dart';

import 'upload_validation_badge.dart';

/// Tarjeta de carga de imagen con overlay de procesamiento
/// y badge de validación superpuesto.
class UploadImageCardWithOverlay extends StatelessWidget {
  const UploadImageCardWithOverlay({
    super.key,
    required this.mode,
    required this.imagePath,
    required this.isProcessing,
    required this.validation,
    required this.onUploadPressed,
    required this.onValidationBadgeTap,
  });

  final GameMode mode;
  final String? imagePath;
  final bool isProcessing;
  final ValidationResult? validation;
  final void Function(ImageSourceType) onUploadPressed;
  final VoidCallback onValidationBadgeTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ImageUploadCard(
          key: ValueKey(mode),
          gameMode: mode,
          imagePath: imagePath,
          isProcessing: isProcessing,
          onUploadPressed: onUploadPressed,
        ),
        if (isProcessing) _ProcessingOverlay(mode: mode),
        if (!isProcessing && validation != null)
          Positioned(
            top: 12,
            right: 12,
            child: UploadValidationBadge(
              validation: validation!,
              onTap: onValidationBadgeTap,
            ),
          ),
      ],
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay({required this.mode});

  final GameMode mode;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Procesando imagen...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
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
    );
  }
}
