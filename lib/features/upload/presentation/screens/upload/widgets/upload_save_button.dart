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
        _buildButton(colorScheme, isDark),
      ],
    );
  }

  Widget _buildWarningBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: isDark ? 0.35 : 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: isDark ? Colors.orange[300] : Colors.orange[700],
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Algunos datos están incompletos. Puedes guardar de todos modos o reintentar la captura.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDark ? Colors.orange[200] : Colors.orange[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(ColorScheme colorScheme, bool isDark) {
    final Color bgColor;
    final String label;

    if (isSaving) {
      bgColor = colorScheme.onSurface.withValues(alpha: 0.12);
      label = 'Guardando…';
    } else if (hasInvalidStats) {
      bgColor = Colors.orange;
      label = 'Guardar con datos incompletos';
    } else {
      bgColor = const Color(0xFF059669);
      label = 'Guardar estadísticas';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: isSaving ? null : onSave,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Center(
              child: isSaving
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasInvalidStats
                              ? Icons.save_outlined
                              : Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
