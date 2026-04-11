import 'package:flutter/material.dart';
import 'package:insight/features/upload/domain/entities/stats_collection.dart';
import 'package:insight/features/parser/presentation/utils/game_mode_extensions.dart';

/// Card compacta para las entradas del historial (todas menos la más reciente).
/// Muestra número de sesión, nombre, dots de modos disponibles y win rate.
class HistoryListCard extends StatelessWidget {
  const HistoryListCard({
    super.key,
    required this.collection,
    required this.number,
    required this.totalCount,
    required this.relativeTime,
    required this.formattedDate,
    required this.onTap,
    required this.onOptionsPressed,
  });

  final StatsCollection collection;
  final int number;
  final int totalCount;
  final String relativeTime;
  final String formattedDate;
  final VoidCallback onTap;
  final VoidCallback onOptionsPressed;

  double? get _primaryWr {
    final stats =
        collection.totalStats ??
        collection.rankedStats ??
        collection.classicStats ??
        collection.brawlStats;
    if (stats == null || stats.winRate <= 0) return null;
    return stats.winRate;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wr = _primaryWr;

    Color wrColor = colorScheme.onSurface;
    if (wr != null) {
      if (wr >= 58)
        wrColor = const Color(0xFF059669);
      else if (wr >= 52)
        wrColor = const Color(0xFFD97706);
      else
        wrColor = const Color(0xFFDC2626);
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onOptionsPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: isDark ? 0.1 : 0.12),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              // ── Número de sesión ─────────────────────────────
              _SessionNumber(
                number: number,
                totalCount: totalCount,
                colorScheme: colorScheme,
                isDark: isDark,
              ),

              const SizedBox(width: 12),

              // ── Nombre + fecha + modos ────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          relativeTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Dots de modos disponibles
                        ...collection.availableStats.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: s.mode.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ── Win rate + chevron ────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (wr != null)
                    Text(
                      '${wr.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: wrColor,
                      ),
                    )
                  else
                    Text(
                      '—',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        color: colorScheme.onSurface.withValues(alpha: 0.25),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.25),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionNumber extends StatelessWidget {
  const _SessionNumber({
    required this.number,
    required this.totalCount,
    required this.colorScheme,
    required this.isDark,
  });

  final int number;
  final int totalCount;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
