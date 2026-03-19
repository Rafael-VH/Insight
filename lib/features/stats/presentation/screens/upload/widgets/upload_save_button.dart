import 'package:flutter/material.dart';

class UploadSaveButton extends StatelessWidget {
  const UploadSaveButton({
    super.key,
    required this.isSaving,
    required this.hasInvalidStats,
    required this.onSave,
  });

  final bool isSaving;
  final bool hasInvalidStats;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasInvalidStats) _buildWarningBanner(isDark),
        _buildButton(colorScheme),
      ],
    );
  }

  Widget _buildWarningBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.orange[900]!.withValues(alpha: 0.3)
            : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.orange[700]! : Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: isDark ? Colors.orange[300] : Colors.orange[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Algunos datos están incompletos. Puedes guardar de todos modos o reintentar la captura.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.orange[200] : Colors.orange[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(ColorScheme colorScheme) {
    return ElevatedButton(
      onPressed: isSaving ? null : onSave,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSaving
            ? colorScheme.onSurface.withValues(alpha: 0.12)
            : hasInvalidStats
            ? Colors.orange
            : const Color(0xFF059669),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
      ),
      child: isSaving ? _buildLoadingContent() : _buildLabelContent(),
    );
  }

  Widget _buildLoadingContent() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        SizedBox(width: 12),
        Text('Guardando...'),
      ],
    );
  }

  Widget _buildLabelContent() {
    return Text(
      hasInvalidStats
          ? 'Guardar con Datos Incompletos'
          : 'Guardar Estadísticas',
    );
  }
}
