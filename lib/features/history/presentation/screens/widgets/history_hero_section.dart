import 'package:flutter/material.dart';

/// Sección superior del historial que reemplaza el AppBar.
/// Muestra el título, métricas globales agregadas y los controles de ordenación.
/// Se usa como SliverToBoxAdapter directamente en el CustomScrollView.
class HistoryHeroSection extends StatelessWidget {
  const HistoryHeroSection({
    super.key,
    required this.metrics,
    required this.sortBy,
    required this.isAscending,
    required this.onRefresh,
    required this.onToggleSort,
    required this.onExportImport,
  });

  final HistoryGlobalMetrics metrics;
  final String sortBy;
  final bool isAscending;
  final VoidCallback onRefresh;
  final void Function(String) onToggleSort;
  final VoidCallback onExportImport;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Título + acciones ───────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historial',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tu rendimiento a lo largo del tiempo',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Botones de acción compactos
              _ActionIconBtn(
                icon: Icons.refresh_rounded,
                onTap: onRefresh,
                tooltip: 'Actualizar',
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 6),
              _ActionIconBtn(
                icon: Icons.import_export_rounded,
                onTap: onExportImport,
                tooltip: 'Exportar / Importar',
                colorScheme: colorScheme,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Métricas globales ───────────────────────────────
          if (metrics.total > 0) ...[
            Row(
              children: [
                Expanded(
                  child: _MetricPill(
                    value: '${metrics.total}',
                    label: 'Sesiones',
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricPill(
                    value: metrics.avgWr > 0 ? '${metrics.avgWr.toStringAsFixed(1)}%' : '—',
                    label: 'WR prom.',
                    accent: metrics.avgWr >= 50
                        ? const Color(0xFF059669)
                        : metrics.avgWr > 0
                        ? const Color(0xFFD97706)
                        : null,
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricPill(
                    value: metrics.avgKda > 0 ? metrics.avgKda.toStringAsFixed(2) : '—',
                    label: 'KDA prom.',
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // ── Controles de ordenación ─────────────────────────
          Row(
            children: [
              _SortChip(
                label: 'Fecha',
                icon: Icons.calendar_today_rounded,
                isActive: sortBy == 'date',
                isAscending: sortBy == 'date' ? isAscending : null,
                onTap: () => onToggleSort('date'),
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 6),
              _SortChip(
                label: 'Nombre',
                icon: Icons.sort_by_alpha_rounded,
                isActive: sortBy == 'name',
                isAscending: sortBy == 'name' ? isAscending : null,
                onTap: () => onToggleSort('name'),
                colorScheme: colorScheme,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Divisor sutil
          Divider(height: 1, thickness: 0.5, color: colorScheme.outline.withValues(alpha: 0.15)),
        ],
      ),
    );
  }
}

// ── Píldora de métrica ────────────────────────────────────────────

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.value,
    required this.label,
    required this.colorScheme,
    required this.isDark,
    this.accent,
  });

  final String value;
  final String label;
  final Color? accent;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: accent ?? colorScheme.onSurface,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip de ordenación ────────────────────────────────────────────

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isAscending,
    required this.onTap,
    required this.colorScheme,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final bool? isAscending;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.onSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? colorScheme.onSurface : colorScheme.outline.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isActive ? colorScheme.surface : colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: isActive
                    ? colorScheme.surface
                    : colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            if (isActive && isAscending != null) ...[
              const SizedBox(width: 4),
              Icon(
                isAscending! ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 10,
                color: colorScheme.surface,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Botón de icono compacto ───────────────────────────────────────

class _ActionIconBtn extends StatelessWidget {
  const _ActionIconBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    required this.colorScheme,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15), width: 0.5),
          ),
          child: Icon(icon, size: 17, color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}

// ── Modelo de métricas globales ───────────────────────────────────

class HistoryGlobalMetrics {
  final int total;
  final double avgWr;
  final double avgKda;

  const HistoryGlobalMetrics({required this.total, required this.avgWr, required this.avgKda});
}
