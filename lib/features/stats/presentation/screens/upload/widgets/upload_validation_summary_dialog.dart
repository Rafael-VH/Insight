import 'package:flutter/material.dart';
import 'package:insight/features/stats/domain/entities/game_mode.dart';
import 'package:insight/core/utils/stats_validator.dart';

class UploadValidationSummaryDialog {
  const UploadValidationSummaryDialog._();

  static void show({
    required BuildContext context,
    required List<GameMode> availableModes,
    required ValidationResult? Function(GameMode) getValidation,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Resumen de Validación\n');

    for (final mode in availableModes) {
      final validation = getValidation(mode);
      if (validation != null) {
        buffer.writeln('${mode.shortName}:');
        buffer.writeln('  ${validation.summary}');
        buffer.writeln('  Completitud: ${validation.completionPercentage.toStringAsFixed(1)}%');
        buffer.writeln();
      }
    }

    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('Resumen de Validación', style: TextStyle(color: colorScheme.onSurface)),
        content: SingleChildScrollView(
          child: Text(buffer.toString(), style: TextStyle(color: colorScheme.onSurface)),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ),
    );
  }
}
