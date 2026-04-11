import 'package:flutter/material.dart';

/// AppBar con título y botón de resumen de validación.
/// Ahora incluye una barra de progreso de 3 pasos debajo del título.
class UploadAppBar extends StatelessWidget implements PreferredSizeWidget {
  const UploadAppBar({
    super.key,
    required this.title,
    required this.hasStats,
    required this.completedSteps,
    required this.onShowSummary,
  });

  final String title;
  final bool hasStats;

  /// Cuántos pasos están completados (0, 1 o 2).
  /// 0 = sin imagen · 1 = imagen cargada · 2 = stats extraídas
  final int completedSteps;
  final VoidCallback onShowSummary;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 52);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        if (hasStats)
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: onShowSummary,
            tooltip: 'Ver resumen de validación',
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: _StepProgressBar(completedSteps: completedSteps),
      ),
    );
  }
}

// ── Barra de pasos ────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.completedSteps});

  final int completedSteps;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    const steps = ['Imagen', 'Revisión', 'Guardar'];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final i = entry.key;
          final label = entry.value;
          final isDone = i < completedSteps;
          final isActive = i == completedSteps;
          final isLast = i == steps.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Círculo del paso
                          _StepCircle(
                            index: i + 1,
                            isDone: isDone,
                            isActive: isActive,
                            colorScheme: colorScheme,
                          ),
                          // Línea conectora (excepto el último)
                          if (!isLast)
                            Expanded(
                              child: Container(
                                height: 1.5,
                                color: isDone
                                    ? colorScheme.primary
                                    : colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive || isDone ? FontWeight.w600 : FontWeight.normal,
                            color: isDone
                                ? colorScheme.primary
                                : isActive
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.index,
    required this.isDone,
    required this.isActive,
    required this.colorScheme,
  });

  final int index;
  final bool isDone;
  final bool isActive;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone
            ? colorScheme.primary
            : isActive
            ? colorScheme.primary
            : colorScheme.outline.withValues(alpha: 0.2),
        border: isActive && !isDone ? Border.all(color: colorScheme.primary, width: 2) : null,
      ),
      child: Center(
        child: isDone
            ? Icon(Icons.check_rounded, size: 13, color: colorScheme.onPrimary)
            : Text(
                '$index',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
      ),
    );
  }
}
