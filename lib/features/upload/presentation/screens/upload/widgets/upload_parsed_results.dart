import 'package:flutter/material.dart';
import 'package:insight/features/parser/utils/mlbb_validator.dart';
import 'package:insight/features/parser/domain/entities/game_mode.dart';
import 'package:insight/features/parser/domain/entities/player_performance.dart';
import 'package:insight/features/parser/presentation/utils/game_mode_extensions.dart';
import 'package:insight/features/insights/presentation/widgets/session_stats_card.dart';

/// Sección de resultados de extracción.
///
/// Muestra un resumen compacto de completitud + tabla de campos
/// por cada modo procesado, seguido del widget de verificación completo.
class UploadParsedResults extends StatelessWidget {
  const UploadParsedResults({super.key, required this.parsedStats, required this.hasInvalidStats});

  final Map<GameMode, PlayerPerformance?> parsedStats;
  final bool hasInvalidStats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final validEntries = parsedStats.entries.where((e) => e.value != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Encabezado de la sección ─────────────────────────
        Row(
          children: [
            Text(
              'Estadísticas extraídas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (hasInvalidStats) _IncompleteChip(isDark: isDark) else _CompleteChip(isDark: isDark),
          ],
        ),
        const SizedBox(height: 12),

        // ── Tarjeta de resumen por modo ──────────────────────
        ...validEntries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ModeResultCard(
              mode: entry.key,
              stats: entry.value!,
              isDark: isDark,
              colorScheme: colorScheme,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Chips de estado global ────────────────────────────────────────

class _CompleteChip extends StatelessWidget {
  const _CompleteChip({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 12, color: Colors.green[isDark ? 300 : 700]),
          const SizedBox(width: 4),
          Text(
            'Datos completos',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.green[isDark ? 300 : 700],
            ),
          ),
        ],
      ),
    );
  }
}

class _IncompleteChip extends StatelessWidget {
  const _IncompleteChip({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 12, color: Colors.orange[isDark ? 300 : 700]),
          const SizedBox(width: 4),
          Text(
            'Datos incompletos',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.orange[isDark ? 300 : 700],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de resultado por modo ─────────────────────────────────

class _ModeResultCard extends StatefulWidget {
  const _ModeResultCard({
    required this.mode,
    required this.stats,
    required this.isDark,
    required this.colorScheme,
  });

  final GameMode mode;
  final PlayerPerformance stats;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  State<_ModeResultCard> createState() => _ModeResultCardState();
}

class _ModeResultCardState extends State<_ModeResultCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final validation = StatsValidator.validate(widget.stats);
    final pct = validation.completionPercentage;
    final modeColor = widget.mode.color;

    return Container(
      decoration: BoxDecoration(
        color: widget.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.colorScheme.outline.withValues(alpha: widget.isDark ? 0.2 : 0.12),
        ),
      ),
      child: Column(
        children: [
          // ── Header colapsable ──────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: modeColor.withValues(alpha: widget.isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.mode.icon, color: modeColor, size: 15),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.mode.fullDisplayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: widget.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Barra de progreso de completitud
                        _CompletionBar(
                          percentage: pct,
                          modeColor: modeColor,
                          isDark: widget.isDark,
                          colorScheme: widget.colorScheme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Porcentaje
                  Text(
                    '${pct.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _percentageColor(pct),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chevron
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: widget.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Contenido expandible ───────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(
                  height: 1,
                  indent: 14,
                  endIndent: 14,
                  color: widget.colorScheme.outline.withValues(alpha: widget.isDark ? 0.15 : 0.1),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                  child: _QuickFieldsTable(
                    validation: validation,
                    isDark: widget.isDark,
                    colorScheme: widget.colorScheme,
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 14,
                  endIndent: 14,
                  color: widget.colorScheme.outline.withValues(alpha: widget.isDark ? 0.15 : 0.1),
                ),
                // Widget de verificación completo
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: SessionStatsCard(gameMode: widget.mode, stats: widget.stats),
                ),
              ],
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Color _percentageColor(double pct) {
    if (pct >= 90) return Colors.green;
    if (pct >= 70) return Colors.orange;
    return Colors.red;
  }
}

// ── Barra de completitud inline ───────────────────────────────────

class _CompletionBar extends StatelessWidget {
  const _CompletionBar({
    required this.percentage,
    required this.modeColor,
    required this.isDark,
    required this.colorScheme,
  });

  final double percentage;
  final Color modeColor;
  final bool isDark;
  final ColorScheme colorScheme;

  Color get _barColor {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: percentage / 100,
        minHeight: 5,
        backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
        valueColor: AlwaysStoppedAnimation<Color>(_barColor),
      ),
    );
  }
}

// ── Tabla compacta de campos ──────────────────────────────────────

class _QuickFieldsTable extends StatelessWidget {
  const _QuickFieldsTable({
    required this.validation,
    required this.isDark,
    required this.colorScheme,
  });

  final ValidationResult validation;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    // Mostrar los campos críticos primero (los que faltan arriba)
    final missingEntries = validation.missingFields.take(3).map((f) => (f, null, false)).toList();

    final okEntries = validation.extractedValues.entries
        .where((e) => !e.key.contains('sugerencia'))
        .take(5)
        .map((e) => (e.key, e.value.toString(), true))
        .toList();

    final rows = [...missingEntries, ...okEntries];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      children: rows.map((row) {
        final label = row.$1;
        final value = row.$2;
        final isOk = row.$3;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              // Indicador
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOk
                      ? Colors.green.withValues(alpha: isDark ? 0.25 : 0.12)
                      : Colors.red.withValues(alpha: isDark ? 0.25 : 0.12),
                ),
                child: Icon(
                  isOk ? Icons.check_rounded : Icons.close_rounded,
                  size: 10,
                  color: isOk ? Colors.green[isDark ? 300 : 700] : Colors.red[isDark ? 300 : 700],
                ),
              ),
              const SizedBox(width: 10),
              // Etiqueta
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isOk
                        ? colorScheme.onSurface.withValues(alpha: 0.7)
                        : Colors.red[isDark ? 300 : 700],
                  ),
                ),
              ),
              // Valor
              Text(
                isOk ? (value ?? '—') : 'No detectado',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isOk ? colorScheme.onSurface : Colors.red[isDark ? 300 : 700],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
